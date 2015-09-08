#include <stdio.h>

int main()
{
    union {
        float f;
        unsigned int i;
    } dfloat;
    union {
        double f;
        unsigned long i;
    } ddouble;

    printf("[%s:%d] sizeof(float) %ld sizeof(double) %ld\n", __FUNCTION__, __LINE__, sizeof(float), sizeof(double));
    dfloat.i = 0x3f60be97;
    printf("[%s:%d] f %f\n", __FUNCTION__, __LINE__, dfloat.f);
    printf("[%s:%d] i %x\n", __FUNCTION__, __LINE__, dfloat.i);
    dfloat.f = 3.14159;
    printf("[%s:%d] 2f %f\n", __FUNCTION__, __LINE__, dfloat.f);
    printf("[%s:%d] 2i %x\n", __FUNCTION__, __LINE__, dfloat.i);
    ddouble.f = 3.14159;
    printf("[%s:%d] 2f %f\n", __FUNCTION__, __LINE__, ddouble.f);
    printf("[%s:%d] 2i %lx\n", __FUNCTION__, __LINE__, ddouble.i);
    return 0;
}
