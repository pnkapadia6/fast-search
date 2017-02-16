// Serial implementation of string searching
// a?b gives -> acb, abb, ...
// case insensitive

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int search(char *pat, char *txt)
{
        int M = strlen(pat);
        int N = strlen(txt);
        int cnt = 0;

        int i=0,j,k,d=0;
        /* A loop to slide pat[] one by one */
        for (i = 0; i <= N - M; i++)
        {
                d=0;
                /* Neglecting escape characters */
                if(txt[i]=='\n' || txt[i]==' ' || txt[i]=='\t')
                        continue;
      
                /* For current index i, check for pattern match */
                for (j = 0; j < M; j++)
                {
                        if(pat[j] == '?')
                        {
                                continue;
                        }
                        if (tolower(txt[i+j]) != tolower(pat[j]))
                                break;
                }
      
                if (j == M)  // if pat[0...M-1] = txt[i, i+1, ...i+M-1]
                {
                //      printf("1 at i=%d char->%c\n",i, txt[i]);
                        if(pat[j-1] == '?' && (txt[i+j-1] == ' ' || txt[i+j-1]=='\n' || txt[i+j-1] == '\0' ));
                        else
                                cnt++;
                }
        }

        return cnt;
}

/* Driver program to test above function */
int main()
{
        struct timeval total_st, total_stp, kernel_st, kernel_stp, copy_st, copy_stp;
        gettimeofday(&total_st,NULL);

        char *pat = "ab";
        FILE *fp;
        char ch;
        int cnt=0;

        gettimeofday(&copy_st, NULL);
        fp = fopen("big.txt","r"); // read mode

        fseek(fp, 0L, SEEK_END);
        int sz = ftell(fp);

        char txt[sz];
//      char * txt=(char *)malloc(sz);
        fseek(fp, 0L, SEEK_SET);
        if( fp == NULL )
        {
                perror("Error while opening the file.\n");
                exit(EXIT_FAILURE);
        }
        while( (ch= fgetc(fp) ) != EOF ){
                txt[cnt] = ch;
                cnt++;
        }
        txt[cnt]='\0';

        fclose(fp);

        gettimeofday(&copy_stp, NULL);
        float copy = (copy_stp.tv_sec - copy_st.tv_sec)*1000 + copy_stp.tv_usec/1000.0 - copy_st.tv_usec/1000.0;

        printf("copy time-- %f ms\n", copy);
//      printf("%s",txt);
        gettimeofday(&kernel_st,NULL);

        int total = search(pat, txt);
        gettimeofday(&kernel_stp,NULL);

        printf("Total matches=%d\n",total);
        getchar();
        gettimeofday(&total_stp,NULL);

        float kernel_elapsed = (kernel_stp.tv_sec - kernel_st.tv_sec)*1000 + kernel_stp.tv_usec/1000.0 - kernel_st.tv_usec/1000.0;
        float total_elapsed = (total_stp.tv_sec - total_st.tv_sec)*1000 + total_stp.tv_usec/1000.0 - total_st.tv_usec/1000.0;
        printf("Kernel time-%fms\n", kernel_elapsed);
        printf("Total time-%fms\n", total_elapsed);

        return 0;
}