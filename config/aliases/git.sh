function gitr {
  git fetch -a && git checkout -b $1 origin/$1
}
