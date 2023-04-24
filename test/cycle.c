
void func(int num) {
	num = num / 25;
	for(int j  = 0; j < num; ++j) {
		j++;
	}
}

int main() {
  int count = 255;
  int result = 0;
  for(int i = 0; i < count; i += 10) {
	  result = i + 1;
	  if ( i == 250) {
		  func(i);
	  }
  }
  asm("ecall");
  return result;
}
