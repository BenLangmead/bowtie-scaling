{ ln += 1 }

{
  if((ln % 4) == 2 || (ln % 4) == 0 || (ln % 4) == 1) {
    print substr($0, 0, 50)
  } else {
    print
  }
}
