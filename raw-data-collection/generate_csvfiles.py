import sys
import pandas as pd
import re

from mongoengine import connect, DoesNotExist
from pycoshark.mongomodels import Commit, FileAction, File, CodeEntityState, Project, VCSSystem, Hunk, Issue, Event
from pycoshark.utils import create_mongodb_uri_string
from datetime import datetime

uri = create_mongodb_uri_string(mongo.user, mongo.pwd, mongo.host, mongo.port, mongo.db, False)
connect(mongo.db, host=uri, alias='default')
connect("smartshark_test", host=uri, alias='default')

date_start = datetime(2017, 1, 1)
date_end = datetime(2018, 1, 1)

vcs_systems = [('archiva', 'refs/remotes/origin/master'),
               ('cayenne', 'refs/remotes/origin/master'),
               ('commons-math', 'refs/remotes/origin/master'),
               ('deltaspike', 'refs/remotes/origin/master'),
               ('falcon', 'refs/remotes/origin/master'),
               ('kafka', 'refs/remotes/origin/trunk'),
               ('kylin', 'refs/remotes/origin/master'),
               ('nutch', 'refs/remotes/origin/master'),
               ('storm', 'refs/remotes/origin/master'),
               ('struts', 'refs/remotes/origin/master'),
               ('tez', 'refs/remotes/origin/master'),
               ('tika', 'refs/remotes/origin/master'),
               ('wss4j', 'refs/remotes/origin/trunk'),
               ('zeppelin', 'refs/remotes/origin/master'),
               ('zookeeper', 'refs/remotes/origin/master'),
               ]

regex_comment = re.compile(
    r"(//[^\"\n\r]*(?:\"[^\"\n\r]*\"[^\"\n\r]*)*[\r\n]|/\*([^*]|\*(?!/))*?\*/)(?=[^\"]*(?:\"[^\"]*\"[^\"]*)*$)")
regex_jdoc_line = re.compile(r"(- |\+)\s*(\*|/\*).*")



'''
Excluded issues with more than 5 files affected:
CAY-2287        fix mixed with a major new feature, nearly all changes new feature
MATH-1284       architecture improvement
FALCON-298      incorrectly referenced by 33 commits
FALCON-2097     incorrectly referenced by 33 commits
KAFKA-4481      new feature
KAFKA-4857      new feature
KAFKA-4714      new feature
KAFKA-5995      new feature
KAFKA-4796      findbugs warnings
KAFKA-4894      findbugs warnings
KAFKA-5265      refactoring
KAFKA-4826      findbugs warnings
KAFKA-5043      new feature
KAFKA-4995      findbugs warnings
STORM-2678      new feature
STORM-2845      remove feature
STORM-1997      new feature
TEZ-3744        findbugs warnings
TEZ-3611        new feature
ZEPPELIN-2197   new feature
ZEPPELIN-3090   new feature
'''
excluded_issues = ["CAY-2287", "MATH-1284", "FALCON-298", "FALCON-2097", "KAFKA-4481", "KAFKA-4857", "KAFKA-4714",
                   "KAFKA-5995", "KAFKA-4796", "KAFKA-4894", "KAFKA-5265", "KAFKA-4826", "KAFKA-5043", "KAFKA-4995",
                   "STORM-2678", "STORM-2845", "STORM-1997", "TEZ-3744", "TEZ-3611", "ZEPPELIN-2197", "ZEPPELIN-3090"]


def filename_filter(filename):
    return filename.endswith('.java') and \
           not filename.endswith('package-info.java') and \
           "/test/" not in filename and \
           not filename.startswith("test/")


def filter_hunks(content):
    content = content + '\n'  # required for regex to drop comments
    content = re.sub(regex_comment, "", content)
    removed = ''
    added = ''
    for line in content.split('\n'):
        if not re.match(regex_jdoc_line, line):
            if line.startswith('-'):
                removed += line[1:].strip()
            elif line.startswith('+'):
                added += line[1:].strip()
    return removed != added


for name, master_branch in vcs_systems:
    print('analyzing', name)

    commits_per_issue = {}
    issues_per_commit = {}

    try:
        project_id = Project.objects(name=name).get().id
    except DoesNotExist:
        print('unknown project:', name)
        sys.exit(1)

    cur_vcs_system = VCSSystem.objects(project_id=project_id).get().id

    # 1) fetch commits
    print('fetching commit ids')
    issue_ids = ['LLOC']
    last_commit = None
    commit_bug_map = {}
    for commit in Commit.objects(vcs_system_id=cur_vcs_system,
                                 committer_date__gte=date_start,
                                 committer_date__lt=date_end,
                                 branches=master_branch)\
                        .only('id', 'committer_date', 'revision_hash', 'linked_issue_ids', 'message', 'parents'):
        linked_bugs = []
        if commit.linked_issue_ids is not None and len(commit.linked_issue_ids) > 0:
            for issue in Issue.objects(id__in=commit.linked_issue_ids):
                if issue.external_id in excluded_issues:
                    continue
                resolved = False
                fixed = False
                if issue.issue_type and issue.issue_type.lower() == 'bug':
                    if issue.status in ['resolved', 'closed']:
                        resolved = True
                        fixed |= issue.resolution.lower() != 'duplicated'

                    for e in Event.objects.filter(issue_id=issue.id):
                        resolved |= e.status is not None and \
                                    e.status.lower() == 'status' and \
                                    e.new_value is not None and \
                                    e.new_value.lower() in ['resolved', 'closed']
                        fixed |= e.status is not None and \
                                 e.status.lower() == 'resolution' and \
                                 e.new_value is not None and \
                                 e.new_value.lower() == 'fixed'
                if resolved and fixed:
                    linked_bugs.append(issue.external_id)

        if len(linked_bugs) > 0:
            has_logical_change = False
            first_parent_revision = commit.parents[0]
            for fileaction in FileAction.objects(commit_id=commit.id, parent_revision_hash=first_parent_revision):
                file = File.objects(id=fileaction.file_id).get()
                if filename_filter(file.path):
                    for hunk in Hunk.objects(file_action_id=fileaction.id):
                        if filter_hunks(hunk.content):
                            has_logical_change = True
                            break
            if has_logical_change:
                for issue_id in linked_bugs:
                    if issue_id not in issue_ids:
                        issue_ids.append(issue_id)
                commit_bug_map[commit.revision_hash] = linked_bugs
        if last_commit is None or commit.committer_date > last_commit.committer_date:
            last_commit = commit

    print("number of issues per bugfixing commit:")
    commits_issuecounts = sorted(set([len(value) for value in commit_bug_map.values()]))
    for issuecount in commits_issuecounts:
        print(issuecount, len([len(value) for key, value in commit_bug_map.items() if len(value) == issuecount]))

    # 2) fetch files for last commit
    print('fetching file names for commit', last_commit.id)
    last_commit_ce = Commit.objects(id=last_commit.id).get()

    file_names = []
    for file in CodeEntityState.objects(id__in=last_commit_ce.code_entity_states, ce_type='file'):
        if filename_filter(file.long_name):
            file_names.append(file.long_name)

    print('initializing data frame')
    bug_matrix = pd.DataFrame(0, index=file_names, columns=issue_ids)
    first_problem = True
    for file in CodeEntityState.objects(id__in=last_commit_ce.code_entity_states, ce_type='file'):
        if filename_filter(file.long_name):
            try:
                bug_matrix.at[file.long_name, 'LLOC'] = file.metrics['LLOC']
            except KeyError:
                if first_problem:
                    print('problem for project ', name)
                    first_problem = False

    print('fetching bug data')
    for i, commit in enumerate(Commit.objects(vcs_system_id=cur_vcs_system,
                                              committer_date__gte=date_start,
                                              committer_date__lt=date_end,
                                              branches=master_branch)
                                     .only('id', 'labels', 'committer_date', 'revision_hash', 'parents')):
        if commit.revision_hash in commit_bug_map:
            first_parent_revision = commit.parents[0]
            for fileaction in FileAction.objects(commit_id=commit.id, parent_revision_hash=first_parent_revision):
                file = File.objects(id=fileaction.file_id).get()
                hasLogicalChange = False
                if file.path in bug_matrix.index:
                    for hunk in Hunk.objects(file_action_id=fileaction.id):
                        if filter_hunks(hunk.content):
                            hasLogicalChange = True
                            break
                    if hasLogicalChange:
                        for issue_id in commit_bug_map[commit.revision_hash]:
                            bug_matrix.at[file.path, issue_id] = 1

    for issue_id in bug_matrix:
        files_affected = bug_matrix[issue_id].sum()
        if files_affected > 5:
            print("Files %i: https://issues.apache.org/jira/browse/%s" % (files_affected, issue_id))

    csv_filename = '%s.csv' % name
    print('writing file %s' % csv_filename)
    bug_matrix.to_csv(csv_filename)
