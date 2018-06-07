#include <stdio.h>
#include <sys/stat.h>

#include <CL/cl.h>

#define MAX_SOURCE_SIZE (0x100000)

int main(int argc, char** argv) {
	cl_platform_id* platforms = malloc(2 * sizeof(cl_platform_id));
	cl_uint ret_num_platforms;
	cl_device_id* devices = malloc(2 * sizeof(cl_device_id));
	cl_uint ret_num_devices;
	cl_context context = NULL;
	cl_command_queue queue = NULL;
	cl_program program = NULL;
	cl_kernel kernel = NULL;
	cl_int ret;

	FILE* fp = fopen("./sha1.cl", "r");
	if (!fp)
		printf("Failed to read kernel source.\n");

	char* source_str = malloc(MAX_SOURCE_SIZE);
	size_t source_size = fread(source_str, 1, MAX_SOURCE_SIZE, fp);
	fclose(fp);

	struct stat st;
	if (stat(argv[1], &st) == -1)
		printf("Failed to stat the input file.\n");

	fp = fopen(argv[1], "rb");
	if (!fp)
		printf("Failed to read the input file.\n");

	unsigned long filesize = st.st_size;
	unsigned char file_buf[filesize];

	unsigned long buf_bytes = filesize;

	fread(&file_buf, sizeof(char), filesize, fp);
	fclose(fp);

	unsigned long buf_ints = buf_bytes / sizeof(unsigned int);
	unsigned int* int_buf = calloc(buf_ints, sizeof(unsigned int));

	for (int i = 0; i < buf_ints; i++) {
		int_buf[i] =
			((file_buf[i * sizeof(unsigned int)] << 24) & 0xFF000000) |
			((file_buf[i * sizeof(unsigned int) + 1] << 16) & 0xFF0000) |
			((file_buf[i * sizeof(unsigned int) + 2] << 8) & 0xFF00) |
			(file_buf[i * sizeof(unsigned int) + 3]);
	}

	ret = clGetPlatformIDs(1, platforms, &ret_num_platforms);
	ret = clGetDeviceIDs(platforms[0], CL_DEVICE_TYPE_GPU, 1, devices, &ret_num_devices);

	context = clCreateContext(NULL, 1, devices, NULL, NULL, &ret);

	queue = clCreateCommandQueue(context, devices[0], 0, &ret);

	program = clCreateProgramWithSource(context, 1, (const char**) &source_str, (const size_t*) &source_size, &ret);

	ret = clBuildProgram(program, 1, devices, NULL, NULL, NULL);

	kernel = clCreateKernel(program, "sha1", &ret);

	cl_mem in_buf = clCreateBuffer(context, CL_MEM_READ_ONLY, buf_bytes, NULL, &ret);
	cl_mem in_size = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(unsigned long), NULL, &ret);
	cl_mem res_buf = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 5 * sizeof(unsigned int), NULL, &ret);

	ret = clEnqueueWriteBuffer(queue, in_buf, CL_TRUE, 0, buf_bytes, int_buf, 0, NULL, NULL);
	ret = clEnqueueWriteBuffer(queue, in_size, CL_TRUE, 0, sizeof(unsigned long), &buf_ints, 0, NULL, NULL);
	ret = clEnqueueFillBuffer(queue, res_buf, (unsigned int[1]){0}, sizeof(unsigned long), 0, sizeof(unsigned long), 0, NULL, NULL);

	ret = clSetKernelArg(kernel, 0, sizeof(cl_mem), &in_buf);
	ret = clSetKernelArg(kernel, 1, sizeof(unsigned long), &in_size);
	ret = clSetKernelArg(kernel, 2, sizeof(cl_mem), &res_buf);

	if (ret != CL_SUCCESS)
		printf("%d\n", (int) ret);

	ret = clEnqueueNDRangeKernel(queue, kernel, 1, 0, (unsigned long[1]){1}, NULL, 0, NULL, NULL);
	unsigned int res[5];
	ret = clEnqueueReadBuffer(queue, res_buf, CL_TRUE, 0, 5 * sizeof(unsigned int), &res, 0, NULL, NULL);

	ret = clFlush(queue);

	if (ret != CL_SUCCESS)
		printf("%d\n", (int) ret);

	ret = clFinish(queue);
	ret = clReleaseKernel(kernel);
	ret = clReleaseProgram(program);
	ret = clReleaseCommandQueue(queue);
	ret = clReleaseContext(context);

	printf("\n");
	for (int i = 0; i < 5; i++)
		printf("%08X\n", res[i]);

	free(source_str);
	free(int_buf);
	free(platforms);
	free(devices);

	return 0;
}
