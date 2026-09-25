# ОМП: практика по git

Общий репозиторий группы. Каждый работает в своей ветке `s/<логин>`,
а прогресс всей группы преподаватель показывает на доске.

## 0. Подготовка

1. Примите приглашение в репозиторий (пришло на почту или на github.com/notifications).
2. Проверьте, что можете пушить на GitHub. Проще всего через SSH:

   ```bash
   ssh -T git@github.com        # Hi <логин>! значит все хорошо
   ```

   Если ключа нет: `ssh-keygen -t ed25519`, затем добавьте `~/.ssh/id_ed25519.pub`
   в github.com/settings/keys. Или поставьте gh и сделайте `gh auth login`.

## 1. Регистрация

Дальше `<логин>` это ваш логин на GitHub маленькими буквами.

```bash
cd ~
git clone git@github.com:sigmadt/omp-git-2026.git omp-git
cd omp-git
git switch -c s/<логин>
bash git-quest.sh <логин> ~/git-quest
cp ~/git-quest/receipts.txt students/<логин>.txt
git add students/<логин>.txt
git commit -m "Register <логин>"
git push -u origin s/<логин>
```

После push вы появитесь на доске.

## 2. Задания

Условия лежат в `~/git-quest/*/README.md`. Когда `check.sh` говорит OK, он пишет
квитанцию в `~/git-quest/receipts.txt`. Отправьте ее:

```bash
cd ~/omp-git
cp ~/git-quest/receipts.txt students/<логин>.txt
git commit -am "Solve 04-bisect"
git push
```

Квитанция зависит от вашего логина, поэтому чужая не подойдет: на доске она
загорится красным.

## 3. Общая ветка team

В ветку `team` пушат все. Добавьте в конец `team.txt` строку вида

```
<логин>: любимая команда git и зачем она нужна
```

```bash
git fetch
git switch team
# допишите строку в конец team.txt
git commit -am "Add <логин> to team"
git push
```

Скорее всего push откажут: кто-то успел раньше. Разберитесь сами, чужие строки
не удалять. Попробуйте `git push --force` и посмотрите, что ответит GitHub.
Если в team.txt останутся маркеры конфликта, доска покажет, кто их запушил.

## Правила

- Пушить можно в свою ветку `s/<логин>` и в `team`. В `main` нельзя.
- Флаги и хеши ответов в общий чат не писать.
- Читать `git-quest.sh` до решения можно, но это спойлер.
