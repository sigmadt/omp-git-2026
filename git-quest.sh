#!/usr/bin/env bash
# Практика по git, ОМП 2026.
# Создает папку с шестью заданиями, в каждом есть README.md и check.sh.
# Запуск: bash git-quest.sh <логин на GitHub> [путь, по умолчанию ~/git-quest]
# Работать в WSL лучше в домашней папке (~), а не в /mnt/c: там ломаются права на файлы.
# Читать этот файл до решения значит испортить себе задания :)
set -eu

if [ $# -lt 1 ] || [ -z "$1" ]; then
  echo "Использование: bash git-quest.sh <логин на GitHub> [путь]" >&2
  exit 2
fi
LOGIN="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
DEST="${2:-$HOME/git-quest}"
if [ -e "$DEST" ]; then
  echo "Папка $DEST уже есть. Удалите ее или передайте другой путь." >&2
  exit 1
fi
command -v git >/dev/null 2>&1 || { echo "Нужен git" >&2; exit 1; }
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

# Генерируем без личного конфига, поэтому хеши коммитов у всех одинаковые
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
export HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME" GIT_CONFIG_NOSYSTEM=1
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE 2>/dev/null || true

T=1758790800 # 2025-09-25 12:00 +0300
AUTHORS="Alice Bob Carol Dave Eve Frank Grace Heidi"

as() {
  local email
  email="$(echo "$1" | tr '[:upper:]' '[:lower:]')@omp.example"
  export GIT_AUTHOR_NAME="$1" GIT_COMMITTER_NAME="$1"
  export GIT_AUTHOR_EMAIL="$email" GIT_COMMITTER_EMAIL="$email"
}
tick() {
  T=$((T + 3617))
  export GIT_AUTHOR_DATE="@$T +0300" GIT_COMMITTER_DATE="@$T +0300"
}
commit() { tick; git commit -q "$@"; }
new_repo() {
  mkdir -p "$1" && cd "$1"
  git -c init.defaultBranch=main init -q
  git symbolic-ref HEAD refs/heads/main
}
hash_of() { printf '%s' "$1" | git hash-object --stdin; }
rot13() { printf '%s' "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'; }
check_header() {
  echo '#!/usr/bin/env bash'
  echo '# Не подсматривайте, здесь только хеши ответов :)'
  echo 'QROOT="$(cd "$(dirname "$0")/.." && pwd)"'
  echo '. "$QROOT/.lib.sh"'
}

# ---------------------------------------------------------------- общее
echo "$LOGIN" > "$DEST/.login"
echo "# $LOGIN" > "$DEST/receipts.txt"
cat > "$DEST/.lib.sh" <<'EOF'
# Общий код для check.sh: квитанции о решении
LOGIN="$(cat "$QROOT/.login")"
hsalt() { printf '%s' "$1" | git hash-object --stdin; }
receipt() { # receipt <задание> <соль>
  local code f
  code="$(printf '%s|%s|%s' "$1" "$LOGIN" "$2" | git hash-object --stdin | cut -c1-12)"
  f="$QROOT/receipts.txt"
  { grep -v "^$1 " "$f" | grep -v '^#'; echo "$1 $code"; } | sort > "$f.tmp"
  { echo "# $LOGIN"; cat "$f.tmp"; } > "$f"
  rm -f "$f.tmp"
  echo
  echo "Квитанция: $1 $code (записана в $f)"
  echo "Чтобы она появилась на доске:"
  echo "  cp $f <клон omp-git>/students/$LOGIN.txt"
  echo "  затем commit и push в свою ветку s/$LOGIN"
}
EOF

cat > "$DEST/README.md" <<'EOF'
# Практика: git

| Папка        | Задание                            | Сложность |
|--------------|------------------------------------|-----------|
| 01-server    | Свой GitHub в соседней папке       | *         |
| 02-merge     | Слияние и переименование           | *         |
| 03-lost      | Потерянное: 4 флага                | **        |
| 04-bisect    | Кто сломал калькулятор             | **        |
| 05-rebase    | Причесать историю                  | **        |
| 06-plumbing  | Коммит без git commit              | ***       |

В каждой папке есть README.md с условием и check.sh для проверки.
Если задание решено, check.sh пишет квитанцию в receipts.txt.
Квитанция личная: она зависит от вашего логина, у соседа не подойдет.
Отправляйте receipts.txt в свою ветку общего репозитория, и прогресс появится на доске.

Если что-то сломали, перегенерируйте: bash git-quest.sh <логин> ~/git-quest2
(квитанции из старой папки перенесите руками).

Полезный алиас на всю практику:

    git config --global alias.lg "log --oneline --graph --all --decorate"
EOF

# ---------------------------------------------------------------- 01-server
Q="$DEST/01-server"
mkdir -p "$Q"
git -c init.defaultBranch=main init -q --bare "$Q/server.git"
git --git-dir="$Q/server.git" symbolic-ref HEAD refs/heads/main
(
  cd "$Q"
  git clone -q server.git seed 2>/dev/null
  cd seed
  git symbolic-ref HEAD refs/heads/main
  as Teacher
  printf '# Team project\n\nOwner: nobody\n' > README.md
  git add README.md
  commit -m "Initial commit"
  git push -q origin main
)
rm -rf "$Q/seed"
for who in alice bob; do
  git clone -q "$Q/server.git" "$Q/$who"
  name=Alice
  [ "$who" = bob ] && name=Bob
  git -C "$Q/$who" config user.name "$name"
  git -C "$Q/$who" config user.email "$who@omp.example"
done

cat > "$Q/README.md" <<'EOF'
# 01. Свой GitHub в соседней папке

Сервер для git не обязателен. Здесь server.git это "голый" (bare) репозиторий,
а alice/ и bob/ это два его клона. Вы играете за обоих.

1. Посмотрите, куда смотрит origin: `git remote -v` в alice/.
   Где физически лежит origin/main? (подсказка: .git/refs/remotes)
2. alice: создайте файл, закоммитьте, `git push`.
3. bob: создайте другой файл, закоммитьте, `git push`. Почему отказ?
4. bob: `git fetch`, затем `git lg`. Нарисуйте граф.
   Чем отличаются `git log main..origin/main` и `git log origin/main..main`?
5. bob: `git pull`. Если git ругается на divergent branches, прочитайте сообщение
   и выберите стратегию: merge или rebase. Запушьте.
6. alice: `git pull`. Сравните хеши коммитов у alice и bob.
7. Оба меняют строку Owner в README.md на свое имя. Первый пушит, второй
   разбирается с конфликтом.
8. Опасное: alice коммитит и пушит. bob, не делая fetch, меняет свой последний
   коммит (`git commit --amend`) и пробует
   `git push --force-with-lease`, потом `git push --force`.
   Что стало с коммитом alice на сервере? Как его вернуть?

Проверка: ./check.sh (на сервере должны быть коммиты и от Alice, и от Bob)
EOF
{
  check_header
  cat <<'EOF'
cd "$QROOT/01-server/server.git" || exit 1
authors="$(git log main --format=%an | sort -u)"
ok=1
for a in Alice Bob; do
  echo "$authors" | grep -qx "$a" || { echo "На сервере нет коммитов от $a"; ok=0; }
done
[ $ok = 1 ] || exit 1
echo "OK. Посмотрите на граф: git --git-dir=server.git log --oneline --graph"
receipt 01 server
EOF
} > "$Q/check.sh"

# ---------------------------------------------------------------- 02-merge
Q="$DEST/02-merge"
mkdir -p "$Q"
(
  new_repo "$Q/repo"
  as Alice
  cat > greet.sh <<'EOF'
#!/bin/sh
name=${1:-World}
echo "Hello, $name!"
EOF
  chmod +x greet.sh
  printf 'lang=en\ntimeout=30\nretries=3\n' > config.txt
  printf '# Greeter\n\nRun: ./greet.sh Bob\n' > README.md
  git add -A
  commit -m "Initial commit"

  git checkout -q -b rename
  as Bob
  git mv greet.sh hello.sh
  printf '# Greeter\n\nRun: ./hello.sh Bob\n' > README.md
  git add -A
  commit -m "Rename greet.sh to hello.sh"

  git checkout -q -b lang main
  as Carol
  cat > greet.sh <<'EOF'
#!/bin/sh
name=${1:-World}
if [ "$LANG_UI" = ru ]; then
  echo "Привет, $name!"
else
  echo "Hello, $name!"
fi
EOF
  git add -A
  commit -m "Add Russian greeting"
  printf 'lang=ru\ntimeout=60\nretries=3\n' > config.txt
  git add -A
  commit -m "Switch to Russian and increase timeout"

  git checkout -q main
  as Alice
  printf 'lang=en\ntimeout=45\nretries=3\n' > config.txt
  git add -A
  commit -m "Tune timeout"
)
cat > "$Q/README.md" <<'EOF'
# 02. Слияние и переименование

В repo/ три ветки:
- rename переименовывает greet.sh в hello.sh;
- lang добавляет русское приветствие в greet.sh и меняет config.txt;
- main тем временем тоже поменял config.txt.

Перед началом: `git config --global merge.conflictStyle zdiff3`
(если git старше 2.35, то diff3).

Задание: влить в main сначала rename, потом lang (через git merge).
Итог:
- greet.sh нет, есть hello.sh, и `LANG_UI=ru ./hello.sh Мир` печатает "Привет, Мир!";
- в config.txt ровно три строки: lang=ru, timeout=60, retries=3;
- все закоммичено.

Проверка: ./check.sh

Вопросы:
1. Git не хранит переименования. Почему правки из lang попали в hello.sh?
2. Что показано между ||||||| и =======?
3. Как отменить слияние, которое еще в процессе? А уже закоммиченное?
4. Что такое HEAD^1, HEAD^2 и HEAD~2 после слияния?
EOF
{
  check_header
  echo "EXPECTED=ec2da51e5579048191cc580c9d9a5e41214d97b7"
  cat <<'EOF'
cd "$QROOT/02-merge/repo" || exit 1
fail() { echo "Нет: $1"; exit 1; }
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || fail "переключитесь на main"
[ -z "$(git status --porcelain)" ] || fail "есть незакоммиченные изменения"
git merge-base --is-ancestor rename main || fail "rename не влита в main"
git merge-base --is-ancestor lang main || fail "lang не влита в main"
[ ! -e greet.sh ] || fail "greet.sh все еще существует"
[ -x hello.sh ] || fail "нет исполняемого hello.sh"
[ "$(LANG_UI=ru ./hello.sh Мир)" = "Привет, Мир!" ] || fail "hello.sh не здоровается по-русски"
[ "$(./hello.sh Bob)" = "Hello, Bob!" ] || fail "hello.sh сломал английский"
[ "$(cat config.txt)" = "$(printf 'lang=ru\ntimeout=60\nretries=3')" ] || fail "config.txt не такой"
! git grep -qE '^(<<<<<<<|>>>>>>>|=======)' HEAD || fail "в коммите остались маркеры конфликта"
tree="$(git rev-parse 'main^{tree}')"
[ "$(hsalt "$tree")" = "$EXPECTED" ] || fail "почти! Но файлы отличаются от эталона байт в байт (лишние файлы, пробелы, нет перевода строки в конце?)"
echo "OK! Теперь ответьте на вопросы из README."
receipt 02 "$tree"
EOF
} > "$Q/check.sh"

# ---------------------------------------------------------------- 03-lost
Q="$DEST/03-lost"
mkdir -p "$Q"
F1="$(rot13 'SYNT{nzraq_znxrf_n_arj_pbzzvg}')"
F2="$(rot13 'SYNT{oenapu_vf_whfg_n_cbvagre}')"
F3="$(rot13 'SYNT{tvg_nqq_nyernql_fgberf_gur_svyr}')"
F4="$(rot13 'SYNT{fgnfu_vf_n_pbzzvg_gbb}')"
(
  new_repo "$Q/repo"
  as Dave
  printf '# Service\n\nНичего интересного.\n' > README.md
  printf 'port: 8080\n' > config.yml
  git add -A
  commit -m "Initial commit"

  printf 'port: 8080\ntoken: %s\n' "$F1" > config.yml
  git add -A
  commit -m "Add token to config"
  printf 'port: 8080\ntoken: ${TOKEN}\n' > config.yml
  git add -A
  commit --amend --no-edit

  git checkout -q -b experiment
  as Eve
  printf 'idea: rewrite everything\n' > experiment.txt
  git add -A
  commit -m "Try new approach"
  printf 'idea: rewrite everything\nsecret: %s\n' "$F2" > experiment.txt
  git add -A
  commit -m "Continue experiment"
  git checkout -q main
  git branch -q -D experiment

  as Dave
  printf 'todo: %s\n' "$F3" > notes.txt
  git add notes.txt
  git reset -q --hard

  printf '\nP.S. %s\n' "$F4" >> README.md
  tick
  git stash push -q -m "temporary"
  git stash drop -q >/dev/null
)
cat > "$Q/README.md" <<'EOF'
# 03. Потерянное

В repo/ спрятаны 4 флага вида FLAG{...}. В рабочей папке и в истории main их нет,
`grep -r FLAG .` тоже ничего не найдет. Но git почти ничего не удаляет сразу.

Что тут происходило:
1. Коммит с токеном в config.yml "исправили" через git commit --amend.
2. Ветку experiment удалили через git branch -D.
3. Файл notes.txt добавили в индекс (git add), не закоммитили и сделали git reset --hard.
4. Правку README.md спрятали в git stash, а потом сделали git stash drop.

Проверка: ./check.sh 'FLAG{...}' (каждый флаг отдельно, каждый дает свою квитанцию)

Вопросы:
- Почему grep не находит флаги внутри .git?
- Через сколько времени git удалит эти объекты насовсем и что на это влияет?
EOF
{
  check_header
  echo "H1=$(hash_of "$F1")"
  echo "H2=$(hash_of "$F2")"
  echo "H3=$(hash_of "$F3")"
  echo "H4=$(hash_of "$F4")"
  cat <<'EOF'
[ $# -eq 1 ] || { echo "Использование: ./check.sh 'FLAG{...}'"; exit 2; }
case "$(hsalt "$1")" in
  "$H1") echo "Флаг 1 из 4 (amend) верный"; receipt 03.1 "$1" ;;
  "$H2") echo "Флаг 2 из 4 (удаленная ветка) верный"; receipt 03.2 "$1" ;;
  "$H3") echo "Флаг 3 из 4 (индекс) верный"; receipt 03.3 "$1" ;;
  "$H4") echo "Флаг 4 из 4 (stash) верный"; receipt 03.4 "$1" ;;
  *) echo "Нет такого флага"; exit 1 ;;
esac
EOF
} > "$Q/check.sh"

# ---------------------------------------------------------------- 04-bisect
Q="$DEST/04-bisect"
mkdir -p "$Q"
write_calc() { # write_calc <build> <stage>: 0 inline, 1 через lib, 2 через lib с багом
  {
    echo '#!/bin/sh'
    echo '# calc.sh: prints the sum of two integers'
    echo "# build $1"
    case $2 in
      0) echo 'echo $(( $1 + $2 ))' ;;
      1) echo '. "$(dirname "$0")/lib/math.sh"'; echo 'add $1 $2' ;;
      2) echo '. "$(dirname "$0")/lib/math.sh"'; echo 'add "$1" "$1"' ;;
    esac
  } > calc.sh
  chmod +x calc.sh
}
MSGS=("Update docs" "Fix typo in README" "Add usage example" "Improve wording"
      "Update changelog" "Add FAQ entry" "Clarify install steps" "Reformat notes")
(
  new_repo "$Q/repo"
  mkdir -p docs
  build=1
  stage=0
  set -- $AUTHORS
  for i in $(seq 1 300); do
    n=$(( (i * 5) % 8 + 1 ))
    as "${!n}"
    case $i in
      1)
        write_calc 1 0
        printf '# calc\n\nUsage: ./calc.sh 2 3\n' > README.md
        printf '# Changelog\n' > docs/CHANGELOG.md
        git add -A
        commit -m "Initial commit"
        ;;
      130)
        stage=1
        mkdir -p lib
        printf 'add() {\n  echo $(( $1 + $2 ))\n}\n' > lib/maths.sh
        write_calc $build $stage
        git add -A
        commit -m "Extract add() into lib"
        ;;
      170)
        git mv lib/maths.sh lib/math.sh
        commit -m "Fix lib path"
        ;;
      230)
        stage=2
        write_calc $build $stage
        git add -A
        commit -m "Quote arguments (shellcheck SC2086)"
        ;;
      *)
        if [ $((i % 9)) -eq 0 ]; then
          build=$i
          write_calc $build $stage
          git add -A
          commit -m "Bump build number to $i"
        else
          echo "- change $i" >> docs/CHANGELOG.md
          git add -A
          commit -m "${MSGS[$((i % 8))]}"
        fi
        ;;
    esac
    [ $i -eq 20 ] && git tag v1.0
    case $i in
      130) git rev-parse HEAD > ../.trap ;;
      230) git rev-parse HEAD > ../.answer ;;
    esac
  done
)
ANSWER="$(cat "$Q/.answer")"
TRAP="$(cat "$Q/.trap")"
rm -f "$Q/.answer" "$Q/.trap"
cat > "$Q/README.md" <<'EOF'
# 04. Кто сломал калькулятор

В repo/ калькулятор. В версии v1.0 он работал:

    ./calc.sh 2 3    # 5

Сейчас на main он печатает не то. В истории 300 коммитов, смотреть их глазами не нужно.

Задание: найти коммит, который внес баг, и объяснить, в чем баг.
Инструмент: `git bisect` (см. `git help bisect`, особенно `git bisect run`).

Проверка: ./check.sh <хеш коммита>

После поиска не забудьте `git bisect reset`.
Вопрос: за сколько шагов bisect гарантированно найдет коммит среди 300?
EOF
{
  check_header
  echo "ANSWER=$(hash_of "$ANSWER")"
  echo "TRAP=$(hash_of "$TRAP")"
  cat <<'EOF'
cd "$QROOT/04-bisect/repo" || exit 1
[ $# -eq 1 ] || { echo "Использование: ./check.sh <хеш>"; exit 2; }
full="$(git rev-parse --verify -q "$1^{commit}")" || { echo "Не нашел такой коммит"; exit 1; }
h="$(hsalt "$full")"
if [ "$h" = "$ANSWER" ]; then
  echo "Верно! Автор: $(git log -1 --format=%an "$full"). Объясните, в чем баг."
  receipt 04 "$full"
elif [ "$h" = "$TRAP" ]; then
  echo "Не совсем. В этом коммите калькулятор выдает неверный ответ или вообще не запускается?"
  exit 1
else
  echo "Нет."
  exit 1
fi
EOF
} > "$Q/check.sh"

# ---------------------------------------------------------------- 05-rebase
Q="$DEST/05-rebase"
mkdir -p "$Q"
(
  new_repo "$Q/repo"
  as Frank
  printf '# Parser\n' > README.md
  git add -A
  commit -m "Initial commit"
  git checkout -q -b feature
  printf 'def parse(line):\n    return line.split("=")\n' > parser.py
  git add -A
  commit -m "Add parser"
  printf 'def parse(line):\n    key, valeu = line.strip().split("=", 1)\n    return key, valeu\n' > parser.py
  git add -A
  commit -m "wip"
  printf 'DB_HOST=localhost\nDB_PASSWORD=hunter2\n' > config.env
  git add -A
  commit -m "Add config"
  printf 'def parse(line):\n    key, value = line.strip().split("=", 1)\n    return key, value\n' > parser.py
  git add -A
  commit -m "fix typo"
  printf 'DB_HOST=localhost\n' > config.env
  git add -A
  commit -m "Remove password"
  printf 'from parser import parse\n\nassert parse("a=b") == ("a", "b")\n' > test_parser.py
  git add -A
  commit -m "Add tests"
  printf 'from parser import parse\n\nassert parse("a=b") == ("a", "b")\nassert parse("a=b=c\\n") == ("a", "b=c")\n' > test_parser.py
  git add -A
  commit -m "fix tests"
  git rev-parse HEAD^{tree} > ../.tree
)
TREE="$(cat "$Q/.tree")"
rm -f "$Q/.tree"
cat > "$Q/README.md" <<'EOF'
# 05. Причесать историю

В repo/ ветка feature из 7 коммитов: wip, fix typo, fix tests...
Хуже того, в одном коммите в config.env попал пароль. Потом его удалили,
но в истории он остался навсегда.

Задание: с помощью `git rebase -i main` сделать из feature ровно 3 коммита:

    Add parser
    Add config
    Add tests

Каждый коммит должен содержать законченную версию своих файлов.
Итоговое содержимое файлов не должно измениться.
DB_PASSWORD не должно быть ни в одном коммите feature.

Проверка: ./check.sh

Вопросы:
1. Пароль теперь исчез из .git? Проверьте (вспомните задание 03).
2. Что делать, если ветку с паролем уже запушили на GitHub?
3. Чем отличаются pick, squash, fixup, reword, edit, drop?
EOF
{
  check_header
  echo "TREE=$TREE"
  echo "EXPECTED=8c4731e3e7cffd85ae9b7ed6db7a70c85ca4e936"
  cat <<'EOF'
cd "$QROOT/05-rebase/repo" || exit 1
fail() { echo "Нет: $1"; exit 1; }
[ "$(git rev-parse 'feature^{tree}')" = "$TREE" ] || fail "итоговые файлы в feature изменились"
[ "$(git rev-list --count main..feature)" = 3 ] || fail "в feature должно быть ровно 3 коммита поверх main"
subjects="$(git log --reverse --format=%s main..feature | tr '\n' '|')"
[ "$subjects" = "Add parser|Add config|Add tests|" ] || fail "сообщения коммитов: $subjects"
for c in $(git rev-list main..feature); do
  if git grep -q DB_PASSWORD "$c" -- . ; then
    fail "пароль есть в коммите $(git log -1 --format='%h %s' "$c")"
  fi
done
trees="$(git log --reverse --format=%T main..feature | paste -sd ' ' -)"
[ "$(hsalt "$trees")" = "$EXPECTED" ] || fail "почти! Но промежуточные коммиты не такие: parser.py в Add parser должен быть уже без опечатки"
echo "OK! А теперь вопрос 1 из README."
receipt 05 "$trees"
EOF
} > "$Q/check.sh"

# ---------------------------------------------------------------- 06-plumbing
Q="$DEST/06-plumbing"
mkdir -p "$Q"
( new_repo "$Q/repo" )
cat > "$Q/README.md" <<'EOF'
# 06. Коммит без git commit

В repo/ пустой репозиторий. Сделайте в ветке main коммит:
- сообщение "Commit without commit";
- один файл hand.txt с текстом "made by hand" и переводом строки.

Нельзя: git add, git commit и прочие высокоуровневые команды.
Можно: git hash-object, git update-index или git mktree, git write-tree,
git commit-tree, git update-ref, git cat-file.

Проверка: ./check.sh

Бонус 1: посчитайте хеш blob для hand.txt без git: только printf и shasum (или sha1sum).
Бонус 2: а хеш коммита?
EOF
{
  check_header
  echo "EXPECTED=44d2c03409f3300de690adba43bca59a8e8a4dc3"
  cat <<'EOF'
cd "$QROOT/06-plumbing/repo" || exit 1
fail() { echo "Нет: $1"; exit 1; }
git rev-parse -q --verify main >/dev/null || fail "в main нет коммитов"
[ "$(git rev-list --count main)" = 1 ] || fail "нужен ровно один коммит"
[ "$(git log -1 --format=%B main)" = "Commit without commit" ] || fail "не то сообщение"
[ "$(git ls-tree --name-only main)" = "hand.txt" ] || fail "в коммите должен быть только hand.txt"
[ "$(git cat-file -p main:hand.txt)" = "made by hand" ] || fail "не то содержимое hand.txt"
[ "$(git cat-file -p main:hand.txt | wc -l | tr -d ' ')" = 1 ] || fail "нужен перевод строки в конце"
if git reflog show --format=%gs main 2>/dev/null | grep -q '^commit'; then
  fail "reflog говорит, что тут был git commit :)"
fi
tree="$(git rev-parse 'main^{tree}')"
[ "$(hsalt "$tree")" = "$EXPECTED" ] || fail "почти! Проверьте режим файла: нужен обычный файл 100644"
echo "OK! Хеш blob: $(git rev-parse main:hand.txt). Теперь бонусы."
receipt 06 "$tree"
EOF
} > "$Q/check.sh"

chmod +x "$DEST"/*/check.sh
echo "Готово: $DEST (логин $LOGIN)"
echo "Начните с $DEST/README.md"
