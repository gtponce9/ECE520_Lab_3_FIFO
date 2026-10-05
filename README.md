# ECE520-Lab-3
Garrett Ponce

BRAM FIFO

## Project Abstract

Created a FIFO using a 2d array to store 32 entries, each 16 bits wide. The code was configured to hold an active high reset that would return read and write pointers to 0. Flag were added to demonstrate when the FIFO was empty, full, almost empty, and almost full. the REAL_MATH library was used to count how many entries were in the FIFO at any time.  A python script was used to generate 32 entries that was read through the testbench READ.io library. Simulation Waveforms will demonstrate proper performance of the code

## Hardware
- Windows 10 Computer with software installed

## Software
- Vivado 2023.2

## Prelab Code

No prelab code was performed for this lab

## Post lab Code

### General Goal
The post lab encompasses the whole lab. In layman terms, assuming write and read enable are high and reset is low, 32 entries are written into a FIFO, were a 2D array functions as a BRAM, and then 32 entries are read from the FIFO, using a 50MHz (20ns) clock, where each entry is loaded on the rising edge of the clock. Once all 32 entries are written, 2 clock cycles pass, and then all 32 entries are read, demonstrating the full capacity of the code. 

### Overflow/Underflow
The code also ignores overflow and underflow, by incorporating 2 signals, Do_Read and Do_Write. Do_Read functions is high only when read_en is high and empty is false. Do_Write is high when write_en is high and full is false. We can determine if our FIFO is full or empty by using a counter that follows how how full/empty the FIFO is based on the amount of reads and writes that occur. 

### IEEE.MATH_REAL
The Counter is also used in the count_data output that uses the MATH_REAL library, that accurately report the number of words available in the FIFO in the correct amount of bits. Since the amount of entries was 32, 6 bits were needed. the following function was used to convert the amount of entires into the amount of bits needed to represent it: 

    constant COUNT_WIDTH : natural := integer(ceil(log2(real(DEPTH+1))));

This plus the position of the counter would tie back to the output "Data_Count" using the following code, that would input the counter value using count_width amount of bits (6 bits)

    data_count   <= std_logic_vector(to_unsigned(Counter, COUNT_WIDTH));

### Reading and Writing

As mentioned earlier, the goal of the assignment is to read and write into and out of a 2D array using the principals of first in, first out. The testbench however demonstrates that not only can this code read and write, but both read and write can occur at the same time, and that the active high reset will reset the read and write pointers, returning the FIFO to an empty state. The internal memory of the FIFO however is not wiped during the rest process. 

please refer to figure 1 that shows the simulation waveform with visuals on where each test occurs.


![Figure 1: Testbench Waveform (Post Lab)](https://github.com/gtponce9/ECE520_Lab_3_FIFO/blob/c1d2ab28a1afda4af539f3ed839f69b61133d626/Testbench_Waveform.png)

## Overview

This lab was pretty confusing, and the python stuff was not intuitive. I'm not even sure if I did it correctly to be quite frank

The 2D array makes alot more sense that instantiating the BRAM and made the top level coding alot more clear

A lot of reading had to go into understanding why I needed the latency (makes more sense, it's basically adding flip flops to slow stuff down so everything arrives at the same time)

I will introduce the waveform to you on Monday and hopefully all is good


