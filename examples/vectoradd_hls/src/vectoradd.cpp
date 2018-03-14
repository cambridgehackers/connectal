

void vectoradd(const int in0[64], const int in1[64], int out[64])
{
#pragma HLS interface ap_hs port=in0
#pragma HLS interface ap_hs port=in1
#pragma HLS interface ap_hs port=out
	for (int i = 0; i < 64; i++)
#pragma unroll 4
		out[i] = in0[i] + in1[i];
}
