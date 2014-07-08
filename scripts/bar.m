source("foo.m");

om3 = m1*m2;

max_error_m3  = 0.0;
max_error_tm3 = 0.0;
max_error_om3 = 0.0;

#calculate a few dot products along the diagonal
#see if the dot products agree with m3 and tm3
for i = 1:size(m1)(1)
  printf("dp: %d\n", i);
  dp = m1(i,:)*m2(:,i);
  max_error_m3  = max(abs(m3(i,i)-dp),max_error_m3);
  max_error_tm3 = max(abs(tm3(i,i)-dp),max_error_tm3);
  max_error_om3 = max(abs(om3(i,i)-dp),max_error_om3);
endfor


max_error_m3
max_error_tm3
max_error_om3


