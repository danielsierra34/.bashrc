alias iadnode_connect='ssh -i vm.pem userngds@172.200.151.176'

git_push_dev_test() {
    if [ -z "$1" ]; then
        echo "Uso: git_push_dev_test \"mensaje de commit\""
        return 1
    fi
    ssh_activar debian-o-ngds || return 1
    git checkout develop || return 1
    git add . || return 1
    git commit -m "$1" || return 1
    git push || return 1
    git checkout test || return 1
    git merge develop --no-edit || return 1
    git push || return 1
    git checkout develop || return 1
}
