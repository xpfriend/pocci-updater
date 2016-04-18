Pocci Updater
=============

Pocciの更新作業を省力化するためのツール

使用法
------
### 事前準備
1.  pocci-box イメージを使ってサーバVMを作成する。
1.  以下のようなファイルを作成する。
    ```yaml
      - path: /root/scripts/setup-pocci.sh
        permissions: '0755'
        owner: root:root
        content: |
            #!/bin/bash
            echo "Skip: pocci setup"
    ```

    ```yaml
      - path: /root/scripts/postprocess.sh
        permissions: '0755'
        owner: root:root
        content: |
            #!/bin/bash
            sed -e 's/送受信可能なメールアドレス/pocci@localhost.localdomain/g' -i /etc/aliases
            newaliases
            sed -e 's/sendmail ${RECIPIENT}/sendmail -f ${ALERT_MAIL_FROM} ${RECIPIENT}/' -i /opt/pocci-box/scripts/notify-by-mail
    ```

    ```yaml
      - path: /tmp/pocci-updater-task-schedule.txt
        permissions: '0644'
        owner: root:root
        content: |
            0 4 * * 1-5 /opt/pocci-box/pocci-updater/bin/update.sh 2>&1 | mail -s "Pocci Updater" -aFrom:送受信可能なメールアドレス 送受信可能なメールアドレス
    ```

    ```yaml
      - path: /tmp/setup-git-user.sh
        permissions: '0755'
        owner: pocci:pocci
        content: |
            #!/bin/bash
            git config --global user.name "GitHubユーザー"
            git config --global user.email "GitHubユーザーのメールアドレス"
    ```

    ```yaml
      - path: /tmp/get-token.sh
        permissions: '0755'
        owner: pocci:pocci
        content: |
            WORKSPACE_BASE_TOKEN="xpfriend/workspace-baseのビルドトリガートークン"
            WORKSPACE_NODEJS_TOKEN="xpfriend/workspace-nodejsのビルドトリガートークン"
            WORKSPACE_JAVA_TOKEN="xpfriend/workspace-javaのビルドトリガートークン"
            WORKSPACE_PYTHON27_TOKEN="xpfriend/workspace-python27のビルドトリガートークン"
            POCCI_ACCOUNT_CENTER_TOKEN="xpfriend/pocci-account-centerのビルドトリガートークン"
            JENKINS_TOKEN="xpfriend/jenkinsのビルドトリガートークン"
            FLUENTD_TOKEN="xpfriend/fluentdのビルドトリガートークン"
            SONARQUBE_TOKEN="xpfriend/sonarqubeのビルドトリガートークン"
    ```

    ```yaml
      - path: /user_data/environment.sh
        permissions: '0755'
        owner: root:root
        content: |
            export timezone="Asia/Tokyo"
            export smtp_relayhost="[メール送信先ホスト]:メール送信先ポート番号"
            export smtp_password="SMTP認証時のパスワード"
            export admin_mail_address="送受信可能なメールアドレス"
            export daily_backup_hour=-
            export timely_backup_hour=-
            export on_provisioning_finished="/root/scripts/postprocess.sh"

            cat <<EOF > /home/pocci/.ssh/id_rsa
            -----BEGIN RSA PRIVATE KEY-----
            GitHubに登録したキーの秘密鍵
            -----END RSA PRIVATE KEY-----
            EOF

            chmod 600 /home/pocci/.ssh/id_rsa
            chown pocci:pocci /home/pocci/.ssh/id_rsa

            sudo -u pocci /bin/bash <<EOF
            set -ex
            ssh-keyscan -H github.com >> /home/pocci/.ssh/known_hosts
            cd /opt/pocci-box
            git clone git@github.com:xpfriend/pocci-updater.git
            git config --global core.editor "vi"
            EOF

            mv /tmp/setup-git-user.sh /opt/pocci-box/pocci-updater/bin
            mv /tmp/get-token.sh /opt/pocci-box/pocci-updater/bin

            sed -e 's/export KANBAN_REPOSITORY/#export KANBAN_REPOSITORY/' -i /etc/profile.d/pocci.sh
    ```

1.  `/root/scripts/setup.sh` を実行する。


### 運用方法
1.  メール通知を確認する。
1.  アップデート処理が実行されなかった場合は特に何もする必要がない。
1.  アップデート処理が正常終了している場合は、以下の対応を行う。
    1.  必要に応じて追加のリグレッションテストを行う。
    1.  `pocci-updater/bin/release-pocci.sh` を実行する。
1.  アップデート処理がエラーになっている場合は、以下の対応を行う
    1.  ログを確認しエラーの修正を行う。
        *   ログは `pocci-updater/bin/log/*` に格納されている。
        *   pocci ソースコードを修正した場合、
            スクリプトの再実行前に `git commit` が必要。
    1.  停止したスクリプトの再実行を行う。
        *   どのスクリプトから実行するかはログをみて判断する。
        *   通常の実行順序は、`pocci-updater/bin/update.sh`  で確認可能。
        *   `pocci-updater/bin/test-pocci.sh`  で停止した場合は、
            実行時引数に停止したstageの番号を指定することにより、
            正常終了したテストをスキップして再実行することができる。
    1.  `pocci-updater/bin/release-pocci.sh` を実行する。
        *   エラー対応でpocci ソースコードを修正した場合、
            relsease-pocci.sh の実行前にコミットを一つにまとめる必要がある。
            `git rebase -i` を実行し、コミットを一つにまとめる。
