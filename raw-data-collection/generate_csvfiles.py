import sys
import pandas as pd

from mongoengine import connect, DoesNotExist
from pycoshark.mongomodels import Commit, FileAction, File, CodeEntityState, Project, VCSSystem
from pycoshark.utils import create_mongodb_uri_string
from datetime import datetime

mongo.user = "USER"
mongo.pwd = "FOOBAR"
mongo.host = "localhost"
mongo.port = 27017
mongo.db = "smartshark"

uri = create_mongodb_uri_string(mongo.user, mongo.pwd, mongo.host, mongo.port, mongo.db, False)
connect(mongo.db, host=uri, alias='default')

label_of_interest = 'issueonly_bugfix'
date_start = datetime(2017,1,1)
date_end = datetime(2018,1,1)

vcs_systems = [('archiva', 'refs/remotes/origin/master'),
               ('calcite', 'refs/remotes/origin/master'),
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

for name, master_branch in vcs_systems:
    print('analyzing', name)

    try:
        project_id = Project.objects(name=name).get().id
    except DoesNotExist:
        print('unknown project:', name)
        sys.exit(1)

    cur_vcs_system = VCSSystem.objects(project_id=project_id).get().id

    # 1) fetch commits
    print('fetching commit ids')
    commit_ids = ['LLOC']
    last_commit = None
    for commit in Commit.objects(vcs_system_id=cur_vcs_system,
                                 committer_date__gte=date_start,
                                 committer_date__lt=date_end,
                                 branches=master_branch).only('id', 'labels', 'committer_date','revision_hash'):
        if commit.labels[label_of_interest]:
            java = False
            for fileaction in FileAction.objects(commit_id=commit.id):
                file = File.objects(id=fileaction.file_id).get()
                if file.path.endswith('.java') and not file.path.endswith('package-info.java'):
                    java = True
            if java:
                commit_ids.append(commit.revision_hash)
        if last_commit is None or commit.committer_date>last_commit.committer_date:
            last_commit = commit

    # 2) fetch files for last commit
    print('fetching file names for commit', last_commit.id)
    last_commit_ce = Commit.objects(id=last_commit.id).get()

    file_names = []
    for file in CodeEntityState.objects(id__in=last_commit_ce.code_entity_states, ce_type='file'):
        if file.long_name.endswith('.java') and not file.long_name.endswith('package-info.java'):
            file_names.append(file.long_name)

    print('initializing data frame')
    bug_matrix = pd.DataFrame(0, index=file_names, columns=commit_ids)
    first_problem = True
    for file in CodeEntityState.objects(id__in=last_commit_ce.code_entity_states, ce_type='file'):
        if file.long_name.endswith('.java') and not file.long_name.endswith('package-info.java'):
            try:
                bug_matrix.at[file.long_name, 'LLOC'] = file.metrics['LLOC']
            except KeyError:
                if first_problem:
                    print('problem for project ', name)
                    first_problem = False
                #print(file.id)
                #sys.exit()

    print('fetching bug data')
    num_bugfixes = 0
    only_others = 0
    for i,commit in enumerate(Commit.objects(vcs_system_id=cur_vcs_system,
                                                  committer_date__gte=date_start,
                                                  committer_date__lt=date_end,
                                                  branches=master_branch).only('id', 'labels', 'committer_date', 'revision_hash')):
        if commit.labels[label_of_interest]:
            num_bugfixes = num_bugfixes+1
            java = False
            others = False
            for fileaction in FileAction.objects(commit_id=commit.id):
                file = File.objects(id=fileaction.file_id).get()
                if file.path in bug_matrix.index:
                    bug_matrix.at[file.path, commit.revision_hash] = 1
                    java = True
                else:
                    others = True
            if not java and others:
                only_others = only_others+1

    filename = '%s.csv' % name
    print(num_bugfixes)
    print(only_others)
    print('writing file %s' % filename)
    bug_matrix.to_csv(filename)
