{ ln += 1 }

{
  if((ln % 4) == 2 || (ln % 4) == 0) {
    print substr($1, 0, 50)
  } else {
    print
  }
}
