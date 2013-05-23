
SECTIONS 
{
         .textr (0x800000): {
	     r.tmp(.data);
         }
         .textd (0x1000000): {
	     d.tmp(.data);
         }
         .textz (0x1008000): {
             start = .;
             c.tmp(.data);
             z.tmp(.data);
         }
}
