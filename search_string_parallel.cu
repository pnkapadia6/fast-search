// Parallel implementation of string searching
// a?b gives -> acb, abb, ...
// case insensitive
// using local memory
// blocks & threads

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdio>
#include <math.h>

using namespace std;

/* M - window size */
#define M 20    

__global__ void searchKeywordKernel(int *result, char *data, char *keyword,int keyword_len)
{
        int i = blockIdx.x * blockDim.x + threadIdx.x , j;
        result[i]=0;
        char * s= (char *) malloc (M + keyword_len -1);
        for (j = 0; j < M + keyword_len - 1; j++)
        {
                s[j] = data[j + (i * M)];
        }
        s[j]='\0';
        keyword[keyword_len]='\0';
//      printf("TT Keyword=%s   %d\n",keyword, keyword_len);
//      printf("Line %d -> %s  M = %d\n", i, s, M);
        bool flag=0;
        int k=0;
        for (int j = 0; j <= M; j++)
        {
                if(s[j] >= 65 && s[j] <= 90)
                        s[j]+=32;
                if (s[j] == keyword[0] || keyword[0]=='?')
                {
                        flag=0;
                        for (k = 1; k < keyword_len; k++)
                        {
                                if(keyword[k]=='?')
                                        continue;
                                if(s[k+j] >= 65 && s[k+j] <= 90)
                                        s[k+j] += 32;
                                if (s[k + j] != keyword[k] || s[k + j]==' ' || s[k + j]=='\n')
                                {
                                        flag=0;
                                        break;
                                }
                                else
                                {
                                        flag=1;
                                }
                        }

                        if(flag==1)
                                result[i]=result[i]+1;

                }
        }
        __syncthreads();
}

int main()
{
        cudaEvent_t k_start, k_stop, t_start, t_stop, c_start, c_stop;
        cudaEventCreate(&t_start);
        cudaEventCreate(&t_stop);
        cudaEventRecord(t_start, 0);

        cudaEventCreate(&c_start);
        cudaEventCreate(&c_stop);
        cudaEventRecord(c_start, 0);

        std::ifstream t("text_150.txt");
        std::stringstream buffer;
        buffer << t.rdbuf();

        string data_s = buffer.str();
        const char *data = data_s.c_str();

        cudaEventRecord(c_stop, 0);
        cudaEventSynchronize(c_stop);
        float copy_time;
        cudaEventElapsedTime(&copy_time, c_start, c_stop);
        printf("\nCopy time: %f msec\n",copy_time);

//      printf("\nM=%d\n", M);
//      printf("Data size = %ld \n",data_s.size());
//      printf("%s\n",data);

        t.close();

        int num_blocks = ceil(data_s.size()/(float)(1024 * M)) ;
        int num_threads = ceil(data_s.size()/(float)(M*num_blocks));

//      printf("No of threads = %d  blocks=%d  \n",num_threads, num_blocks);
        char *keyword = "ab";
        size_t keyword_len = strlen(keyword);

//      printf("Keyword=%s   %ld \n",keyword, keyword_len);

        int *result = (int *) malloc(num_blocks * num_threads * sizeof(int));
        memset(result, 0, num_blocks * num_threads);

        //device data
        char *dev_data = 0;
        char *dev_keyword = 0;
        int *dev_result = 0;

        // Allocate GPU buffers for result set.
        cudaMalloc((void**) &dev_result, num_blocks * num_threads * sizeof(int));
        cudaMalloc((void**) &dev_data, data_s.size() + 1);
        cudaMalloc((void**) &dev_keyword, keyword_len);

        // Copy input data and keyword from host memory to GPU buffers.
        cudaMemcpy(dev_data, data, data_s.size() + 1, cudaMemcpyHostToDevice);
        cudaMemcpy(dev_keyword, keyword, keyword_len, cudaMemcpyHostToDevice);
        cudaMemcpy(dev_result, result, num_blocks * num_threads, cudaMemcpyHostToDevice);

        cudaEventCreate(&k_start);
        cudaEventCreate(&k_stop);
        cudaEventRecord(k_start, 0);

        // Launch a search keyword kernel on the GPU with one thread for each element.
        searchKeywordKernel<<<num_blocks, num_threads>>>(dev_result, dev_data, dev_keyword, keyword_len);
        cudaDeviceSynchronize();

        // Copy result from GPU buffer to host memory.
        cudaMemcpy(result, dev_result, num_blocks * num_threads * sizeof(int),cudaMemcpyDeviceToHost);

        cudaEventRecord(k_stop, 0);
        cudaEventSynchronize(k_stop);
        float kernel_time;
        cudaEventElapsedTime(&kernel_time, k_start, k_stop);
        printf("\nKernel time: %f msec\n",kernel_time);


        printf("\n");
        int total_matches = 0;
        for (int i = 0; i < num_threads * num_blocks; i++)
        {
                if (result[i] > 0)
                {
                //      printf("%d matches found at line %d \n",result[i], i);
                        total_matches=total_matches+result[i];
                }
        }
        printf("Total matches = %d\n", total_matches);
        cudaFree(dev_result);
        cudaFree(dev_data);
        cudaFree(dev_keyword);


        cudaEventRecord(t_stop, 0);
        cudaEventSynchronize(t_stop);
        float total_time;
        cudaEventElapsedTime(&total_time, t_start, t_stop);
        printf("\nTotal time: %f msec\n",total_time);

        return 0;
}