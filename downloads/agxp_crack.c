#include "stdio.h"

typedef struct bytepair BYTEPAIR;

// Struct to hold the offset and patch value pairs.
struct bytepair
{
    long offset;
    char val;
}; 

// Patch constants which include the offset for the byte replacement, and the value of the replacement. 
// I got these values by meddling around in SoftIce.
static const BYTEPAIR byte_pairs[8]= { 
    {0x0003252E, 0x75},
    {0x00039018, 0x84},
    {0x00039151, 0xE8},
    {0x00039152, 0x03},
    {0x0003916F, 0xF4},
    {0x00039170, 0x01},
    {0x0004938D, 0x75},
    {0x00049E9E, 0x75}
};

int main ()
{
    FILE *exeFile = fopen("artgem.exe", "r+");

    if (exeFile == (FILE *)0)
    {
        printf("artgem.exe not found. Aborting.\n\n");
        printf("Hit <Enter> to quit.");
        getchar();
        
        return 1;
    }

    printf("Cracking...\n");

    int i;
    // Patch each byte appearing in array of offset/byte pairs.
    for (i = 0; i < 8; i++)
    {
        // Go to position in file based on stored offset.
        fseek(exeFile, byte_pairs[i].offset, SEEK_SET);

        // Patch the byte.
        fwrite(&byte_pairs[i].val, 1, 1, exeFile);
    }

    // Close file, inform user, and quit.
    fclose(exeFile);

    printf("Done!\n\n");

    getchar();

    return 0;
}