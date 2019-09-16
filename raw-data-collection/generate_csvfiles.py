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
CAY-2313        improvement
CAY-2308        improvement
CAY-2324        improvement
CAY-2240        improvement
CAY-2199        improvement
CAY-2056        test
CAY-2295        improvement
CAY-2388        improvement
CAY-2109        improvement
CAY-2231        improvement
CAY-2243        improvement
CAY-2380        improvement
CAY-2357        improvement
CAY-2222        improvement
CAY-2273        improvement
CAY-2287        fix mixed with a major new feature, nearly all changes new feature
MATH-1284       architecture improvement
MATH-1419       improvement
MATH-1413       improvement
MATH-1436       improvement
DELTASPIKE-1307 improvement
DELTASPIKE-1303 improvement
FALCON-298      incorrectly referenced by 33 commits
FALCON-2097     incorrectly referenced by 33 commits
FALCON-2259     improvement
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
KAFKA-4565      improvement
KAFKA-4434      improvement
KAFKA-3853      improvement
KAFKA-4060      improvement
KAFKA-5576      improvement
KAFKA-5362      improvement
KAFKA-5477      improvement
KAFKA-5140      test
KAFKA-6126      improvement
KAFKA-3856      improvement
KAFKA-5603      improvement
KAFKA-5797      improvement
KAFKA-6174      improvement
KAFKA-5765      improvement
KAFKA-5867      improvement
KAFKA-5051      improvement
KAFKA-6115      improvement
KAFKA-5150      improvement
KAFKA-4785      improvement
KAFKA-3353      improvement
KAFKA-5379      improvement
KAFKA-5350      improvement
KAFKA-4343      improvement
KAFKA-5469      improvement
KAFKA-4039      improvement
KAFKA-4494      improvement
KAFKA-5361      improvement
KAFKA-4878      improvement
KAFKA-5449      improvement
KAFKA-4806      improvement
KAFKA-4993      improvement
KAFKA-4677      improvement
KAFKA-4525      improvement
KAFKA-3070      improvement
KAFKA-4895      improvement
KAFKA-4924      improvement
KAFKA-4631      improvement
KAFKA-4916      improvement
KAFKA-4937      improvement
KAFKA-4667      improvement
KAFKA-4738      improvement
KAFKA-4977      improvement
KAFKA-4756      improvement
KYLIN-2648      improvement
KYLIN-2631      improvement
KYLIN-2577      improvement
KYLIN-2539      improvement
KYLIN-2514      improvement
KYLIN-2243      improvement
KYLIN-1664      improvement
KYLIN-2452      improvement
KYLIN-2441      improvement
KYLIN-2348      improvement
KYLIN-2357      improvement
KYLIN-2342      improvement
KYLIN-2282      improvement
KYLIN-2322      improvement
KYLIN-2463      improvement
KYLIN-2788      improvement
KYLIN-2995      improvement
KYLIN-3106      improvement
KYLIN-3004      improvement
KYLIN-2906      improvement
KYLIN-2794      improvement
KYLIN-2758      improvement
KYLIN-3053      improvement
KYLIN-2716      improvement
KYLIN-2188      improvement
KYLIN-3084      improvement
NUTCH-2465      improvement
NUTCH-2454      improvement
STORM-2678      new feature
STORM-2845      remove feature
STORM-1997      new feature
WW-4578         improvement
TEZ-3744        findbugs warnings
TEZ-3611        new feature
TEZ-3732        improvement
TEZ-3244        improvement
TEZ-3856        improvement
TEZ-3637        improvement
TEZ-3719        improvement
TEZ-3581        improvement
TEZ-3267        improvement
TEZ-3659        improvement
TEZ-3777        improvement
TEZ-3709        improvement
TEZ-3605        improvement
TEZ-3647        improvement
TEZ-3601        improvement
TEZ-3417        improvement
TIKA-2099       improvement
TIKA-2250       improvement
TIKA-2244       improvement
TIKA-2325       improvement
TIKA-2279       improvement
TIKA-2159       improvement
TIKA-1804       improvement
TIKA-2450       improvement
TIKA-2384       improvement
TIKA-2089       improvement
TIKA-2438       improvement
TIKA-2490       improvement
TIKA-2491       improvement
WSS-614         improvement
WSS-558         improvement
WSS-618         improvement
WSS-540         improvement
ZEPPELIN-1908   improvement
ZEPPELIN-2367   improvement
ZEPPELIN-2645   improvement
ZEPPELIN-2970   improvement
ZEPPELIN-2590   improvement
ZEPPELIN-802    improvement
ZEPPELIN-2122   improvement
ZEPPELIN-2067   improvement
ZEPPELIN-2106   improvement
ZEPPELIN-1977   improvement
ZEPPELIN-2197   new feature
ZEPPELIN-3090   new feature
ZOOKEEPER-2573  improvement
ZOOKEEPER-2642  improvement
ZOOKEEPER-2818  documentation
ZOOKEEPER-1932  improvement
ZOOKEEPER-2678  improvement
ZOOKEEPER-2819  improvement
ZOOKEEPER-2914  improvement
ZOOKEEPER-2680  improvement
ZOOKEEPER-2617  improvement

'''

excluded_issues = ['CAY-2056', 'CAY-2109', 'CAY-2199', 'CAY-2222', 'CAY-2231', 'CAY-2240', 'CAY-2243', 'CAY-2273',
                   'CAY-2287', 'CAY-2295', 'CAY-2308', 'CAY-2313', 'CAY-2324', 'CAY-2357', 'CAY-2380', 'CAY-2388',
                   'DELTASPIKE-1303', 'DELTASPIKE-1307', 'FALCON-2097', 'FALCON-2259', 'FALCON-298', 'KAFKA-3070',
                   'KAFKA-3353', 'KAFKA-3835', 'KAFKA-3853', 'KAFKA-3856', 'KAFKA-4039', 'KAFKA-4060', 'KAFKA-4343',
                   'KAFKA-4434', 'KAFKA-4481', 'KAFKA-4494', 'KAFKA-4525', 'KAFKA-4565', 'KAFKA-4631', 'KAFKA-4667',
                   'KAFKA-4677', 'KAFKA-4714', 'KAFKA-4738', 'KAFKA-4756', 'KAFKA-4785', 'KAFKA-4796', 'KAFKA-4806',
                   'KAFKA-4826', 'KAFKA-4857', 'KAFKA-4878', 'KAFKA-4894', 'KAFKA-4895', 'KAFKA-4916', 'KAFKA-4924',
                   'KAFKA-4937', 'KAFKA-4977', 'KAFKA-4993', 'KAFKA-4995', 'KAFKA-5043', 'KAFKA-5051', 'KAFKA-5140',
                   'KAFKA-5150', 'KAFKA-5265', 'KAFKA-5350', 'KAFKA-5361', 'KAFKA-5362', 'KAFKA-5379', 'KAFKA-5449',
                   'KAFKA-5469', 'KAFKA-5477', 'KAFKA-5576', 'KAFKA-5603', 'KAFKA-5765', 'KAFKA-5797', 'KAFKA-5867',
                   'KAFKA-5995', 'KAFKA-6115', 'KAFKA-6126', 'KAFKA-6174', 'KYLIN-1664', 'KYLIN-2188', 'KYLIN-2243',
                   'KYLIN-2282', 'KYLIN-2322', 'KYLIN-2342', 'KYLIN-2348', 'KYLIN-2357', 'KYLIN-2441', 'KYLIN-2452',
                   'KYLIN-2463', 'KYLIN-2514', 'KYLIN-2539', 'KYLIN-2577', 'KYLIN-2631', 'KYLIN-2648', 'KYLIN-2716',
                   'KYLIN-2758', 'KYLIN-2788', 'KYLIN-2794', 'KYLIN-2906', 'KYLIN-2995', 'KYLIN-3004', 'KYLIN-3053',
                   'KYLIN-3084', 'KYLIN-3106', 'MATH-1284', 'MATH-1413', 'MATH-1419', 'MATH-1436', 'NUTCH-2454',
                   'NUTCH-2465', 'STORM-1997', 'STORM-2240', 'STORM-2503', 'STORM-2517', 'STORM-2525', 'STORM-2638',
                   'STORM-2678', 'STORM-2733', 'STORM-2738', 'STORM-2765', 'STORM-2810', 'STORM-2815', 'STORM-2845',
                   'TEZ-3244', 'TEZ-3267', 'TEZ-3417', 'TEZ-3581', 'TEZ-3601', 'TEZ-3605', 'TEZ-3611', 'TEZ-3637',
                   'TEZ-3647', 'TEZ-3659', 'TEZ-3709', 'TEZ-3719', 'TEZ-3732', 'TEZ-3744', 'TEZ-3777', 'TEZ-3856',
                   'TIKA-1804', 'TIKA-2089', 'TIKA-2099', 'TIKA-2159', 'TIKA-2244', 'TIKA-2250', 'TIKA-2279',
                   'TIKA-2325', 'TIKA-2384', 'TIKA-2438', 'TIKA-2450', 'TIKA-2490', 'TIKA-2491', 'WSS-540', 'WSS-558',
                   'WSS-614', 'WSS-618', 'WW-4578', 'ZEPPELIN-1908', 'ZEPPELIN-1977', 'ZEPPELIN-2067', 'ZEPPELIN-2106',
                   'ZEPPELIN-2122', 'ZEPPELIN-2197', 'ZEPPELIN-2367', 'ZEPPELIN-2590', 'ZEPPELIN-2645', 'ZEPPELIN-2970',
                   'ZEPPELIN-3090', 'ZEPPELIN-802', 'ZOOKEEPER-1932', 'ZOOKEEPER-2573', 'ZOOKEEPER-2617',
                   'ZOOKEEPER-2642', 'ZOOKEEPER-2678', 'ZOOKEEPER-2680', 'ZOOKEEPER-2818', 'ZOOKEEPER-2819',
                   'ZOOKEEPER-2914']

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

count_file_actions = 0
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
    cur_issue_system = IssueSystem.objects(project_id=project_id).get().id

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
                        count_file_actions += 1
                        for issue_id in commit_bug_map[commit.revision_hash]:
                            bug_matrix.at[file.path, issue_id] = 1

    csv_filename = '%s.csv' % name
    print('writing file %s' % csv_filename)
    bug_matrix.to_csv(csv_filename)