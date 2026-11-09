# local.sh: the base repository the spec eval fixtures share. A case's
# fixture.sh sources it, then adds its own files and commits. It builds the
# plan suite's tally repo plus a .local/ holding one file, and no .scratch/.
source "$(dirname "$0")/../../plan/tally.sh"
mkdir .local
printf 'Local notes.\n' > .local/notes.md
