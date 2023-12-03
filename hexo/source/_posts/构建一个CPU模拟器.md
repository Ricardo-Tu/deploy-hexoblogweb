---
title: 构建一个CPU模拟器
sticky: false
comments: true
toc: true
toc_number: true
mathjax: false
highlight_shrink: false
aside: true
copyright: false
date: 2023-12-01 12:00:07
updated:
tags: start
categories:
keywords:
description:
cover: 5.png
top_img: /media/top_img.jpg
copyright_author:
copyright_author_href:
copyright_url:
copyright_info:
---

# 一、概述

本章节介绍的是windows环境下unicorn框架和capstone框架的使用。

# 二、工具

Visual stdio 2019

Cmake

Git

# 三、构建步骤

1. clone unicorn和capstone框架的源码。(注意clone的分支为最新版本，不是master)

    ```bash
        git clone https://github.com/unicorn-engine/unicorn.git
        git clone https://github.com/capstone-engine/capstone.git
    ```

2. 编译unicorn

   - 使用git bash或者cmd进入unicorn目录，执行下面几条命令

    ```bash
        mkdir build
        cd build
        cmake .. -G "Visual Studio 16 2019" -A "x64" -DCMAKE_BUILD_TYPE=Release
    ```

   - 接着在build目录下会生成一个unicorn.sln文件，使用visual stdio 2019打开，编译输出。在build目录下会生成unicorn.lib，在build/debug目录下会生成许多文件，只需要unicorn.dll即可

        ![](1.png)

        ![](2.png)

1. 编译capstone

    使用visual stdio 2019打开capstone/msvc目录下的capstone.sln文件，编译之后在capstone\msvc\x64\Debug目录下会生成capstone.dll和capstone.lib文件。

    ![](3.png)

4. 创建模拟器项目

    使用visual stdio 2019创建一个新项目，然后导入上面两步骤生成的文件,再将上述框架中capstone和unicorn头文件(在include目录下)放入工程根目录中。

    ![](4.png)

5. 实现代码
    下面是模拟x86架构64位程序代码片段，其中test_00007FF6B9541000.bin是.text段的内存dump文件，test_00000039AB52A000.bin为.stack段内存dump，test_00007FF6B9549000.bin为.rdata段内存dump，test_00007FF6B954C000.bin为.data段内存dump,test_00007FF6B9531000.bin为.textbss段内存dump。

    ```bash
    
    csh g_x64_cs_handle = NULL;
    cs_insn* g_x64_cs_insn = NULL;
    size_t g_x64_cs_count = 0;  // how many instruction that this capstone API disassembly successfully
    cs_err g_x64_cs_err = CS_ERR_OK;
    
    uc_engine* g_x64_uc = NULL;
    uc_err g_x64_uc_err = UC_ERR_OK;  // error number that unicorn emulate instruction
    
    DWORD64 g_x64_instruction_count = 0;
    
    REG_X86 g_x64_reg = { 0 }; // init register
    
    //#define CODE "\x55\x48\x8b\x05\xb8\x13\x00\x00"
    
    
    VOID x64_init_registers()
    {
    g_x64_reg.reg.r_rax = 0x00007FF6B9541230;
    g_x64_reg.reg.r_rcx =   0x00000039AB77F000;
    g_x64_reg.reg.r_rdx =   0x00007FF6B9541230;
    g_x64_reg.reg.r_rbx =   0x0000000000000000;
    g_x64_reg.reg.r_rsp =   0x00000039AB52FDB8;
    
    g_x64_reg.reg.r_rbp =   0x0000000000000000l;
    g_x64_reg.reg.r_rsi =   0x0000000000000000;
    g_x64_reg.reg.r_rdi =   0x0000000000000000;
    g_x64_reg.reg.r_rip =   0x00007FF6B9542330;
    g_x64_reg.reg.r_rflag = 0x0000000000000246;
    
    g_x64_reg.reg.r_r8 =    0x00000039AB77F000;
    g_x64_reg.reg.r_r9 =    0x00007FF6B9541230;
    g_x64_reg.reg.r_r10 =   0x00007FFFBD807C90;
    g_x64_reg.reg.r_r11 =   0x0000000000000000l;
    g_x64_reg.reg.r_r12 =   0x0000000000000000l;
    
    g_x64_reg.reg.r_r13 =   0x0000000000000000l;
    g_x64_reg.reg.r_r14 =   0x0000000000000000l;
    g_x64_reg.reg.r_r15 =   0x0000000000000000l;
    
    }
    
    x64_FileInformation fileinfo[] =
    {
    //    BaseAddress       FileSize        Path         allocate buffer address
    (PVOID)0x00007FF6B9541000  , 0x8000  , L".\\x64_binary\\test_00007FF6B9541000.bin" ,  NULL , //.text
    (PVOID)0x00000039AB52A000  , 0x6000  , L".\\x64_binary\\test_00000039AB52A000.bin" ,  NULL , //.stack
    (PVOID)0x00007FF6B9549000  , 0x3000  , L".\\x64_binary\\test_00007FF6B9549000.bin" ,  NULL , //.rdata
    (PVOID)0x00007FF6B954C000  , 0x1000  , L".\\x64_binary\\test_00007FF6B954C000.bin" ,  NULL , //.data
    (PVOID)0x00007FF6B9531000  , 0x10000  , L".\\x64_binary\\test_00007FF6B9531000.bin" ,  NULL , //.textbss
    
    };
    
    
    
    VOID x64_emulate()
    {
    g_x64_cs_err = cs_open(CS_ARCH_X86, CS_MODE_64, &g_x64_cs_handle);
    
    g_x64_uc_err = uc_open(UC_ARCH_X86, UC_MODE_64, &g_x64_uc);
    
    if (g_x64_cs_err || g_x64_uc_err)
    {
    printf("ERROR: Failed to initialize engine!\n");
    
    return;
    }
    
    cs_option(g_x64_cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
    
    for (ULONG i = 0; i < sizeof(fileinfo) / sizeof(fileinfo[0]); i++)
    {
    FILE* pFile = NULL;
    
    fileinfo[i].buffer = (PVOID)malloc(fileinfo[i].FileSize);
    
    if (!fileinfo[i].buffer)
    {
    printf("Allocate mem fail!\n");
    
    return;
    }
    
    pFile = _wfopen(fileinfo[i].FileName, L"rb");
    
    if (!pFile)
    {
    printf("open file error code : <%d>\n", GetLastError());
    
    return;
    }
    
    fread(fileinfo[i].buffer, fileinfo[i].FileSize, 1, pFile);
    
    if (pFile)
    fclose(pFile);
    
    g_x64_uc_err = uc_mem_map(g_x64_uc, (DWORD64)fileinfo[i].BaseAddress, fileinfo[i].FileSize, UC_PROT_ALL);
    
    if (g_x64_uc_err)
    {
    printf("uc mem map error!Error Code:<%d>\n", g_x64_uc_err);
    
    return;
    }
    
    g_x64_uc_err = uc_mem_write(g_x64_uc, (DWORD64)fileinfo[i].BaseAddress, fileinfo[i].buffer, fileinfo[i].FileSize);
    
    if (g_x64_uc_err)
    {
    printf("uc mem write error!Error Code:<%d>\n", g_x64_uc_err);
    
    return;
    }
    
    }
    
    x64_init_registers();
    
    x64_write_uc_registers();
    
    BYTE Code[32] = { 0 };
    
    do
    {
    uc_mem_read(g_x64_uc, g_x64_reg.reg.r_rip, Code, sizeof(Code));
    
    g_x64_cs_count = cs_disasm(g_x64_cs_handle, Code, sizeof(Code), g_x64_reg.reg.r_rip, 1, &g_x64_cs_insn);
    
    if (!g_x64_cs_count)
    break;
    
    g_x64_uc_err = uc_emu_start(g_x64_uc, g_x64_reg.reg.r_rip, 0xffffffffffffffff, 0, 1);
    
    x64_read_uc_registers();
    
    x64_print_uc_registers();
    
    x64_print_uc_stack(g_x64_reg.reg.r_rsp);
    
    cs_free(g_x64_cs_insn, 1);
    
    if (g_x64_uc_err)
    {
    printf("uc_emu_start error!Error Code:<%d>\n", g_x64_uc_err);
    
    break;
    }
    
    g_x64_instruction_count++;
    
    } while (g_x64_cs_count);
    
    cs_close(&g_x64_cs_handle);
    
    uc_close(g_x64_uc);
    
    }
    
    
    
    VOID x64_read_uc_registers()
    {
    uc_reg_read(g_x64_uc, UC_X86_REG_RAX, &g_x64_reg.reg.r_rax);
    uc_reg_read(g_x64_uc, UC_X86_REG_RCX, &g_x64_reg.reg.r_rcx);
    uc_reg_read(g_x64_uc, UC_X86_REG_RDX, &g_x64_reg.reg.r_rdx);
    uc_reg_read(g_x64_uc, UC_X86_REG_RBX, &g_x64_reg.reg.r_rbx);
    uc_reg_read(g_x64_uc, UC_X86_REG_RSP, &g_x64_reg.reg.r_rsp);
                
    uc_reg_read(g_x64_uc, UC_X86_REG_RBP, &g_x64_reg.reg.r_rbp);
    uc_reg_read(g_x64_uc, UC_X86_REG_RSI, &g_x64_reg.reg.r_rsi);
    uc_reg_read(g_x64_uc, UC_X86_REG_RDI, &g_x64_reg.reg.r_rdi);
    uc_reg_read(g_x64_uc, UC_X86_REG_RIP, &g_x64_reg.reg.r_rip);
    uc_reg_read(g_x64_uc, UC_X86_REG_RFLAGS, &g_x64_reg.reg.r_rflag);
        
    uc_reg_read(g_x64_uc, UC_X86_REG_R8, &g_x64_reg.reg.r_r8);
    uc_reg_read(g_x64_uc, UC_X86_REG_R9, &g_x64_reg.reg.r_r9);
    uc_reg_read(g_x64_uc, UC_X86_REG_R10, &g_x64_reg.reg.r_r10);
    uc_reg_read(g_x64_uc, UC_X86_REG_R11, &g_x64_reg.reg.r_r11);
    uc_reg_read(g_x64_uc, UC_X86_REG_R12, &g_x64_reg.reg.r_r12);
        
    uc_reg_read(g_x64_uc, UC_X86_REG_R13, &g_x64_reg.reg.r_r13);
    uc_reg_read(g_x64_uc, UC_X86_REG_R14, &g_x64_reg.reg.r_r14);
    uc_reg_read(g_x64_uc, UC_X86_REG_R15, &g_x64_reg.reg.r_r15);
    
    
    }
    
    VOID x64_write_uc_registers()
    {
    uc_reg_write(g_x64_uc, UC_X86_REG_RAX, &g_x64_reg.reg.r_rax);
    uc_reg_write(g_x64_uc, UC_X86_REG_RCX, &g_x64_reg.reg.r_rcx);
    uc_reg_write(g_x64_uc, UC_X86_REG_RDX, &g_x64_reg.reg.r_rdx);
    uc_reg_write(g_x64_uc, UC_X86_REG_RBX, &g_x64_reg.reg.r_rbx);
    uc_reg_write(g_x64_uc, UC_X86_REG_RSP, &g_x64_reg.reg.r_rsp);
        
    uc_reg_write(g_x64_uc, UC_X86_REG_RBP, &g_x64_reg.reg.r_rbp);
    uc_reg_write(g_x64_uc, UC_X86_REG_RSI, &g_x64_reg.reg.r_rsi);
    uc_reg_write(g_x64_uc, UC_X86_REG_RDI, &g_x64_reg.reg.r_rdi);
    uc_reg_write(g_x64_uc, UC_X86_REG_RIP, &g_x64_reg.reg.r_rip);
    uc_reg_write(g_x64_uc, UC_X86_REG_RFLAGS, &g_x64_reg.reg.r_rflag);
        
    uc_reg_write(g_x64_uc, UC_X86_REG_R8, &g_x64_reg.reg.r_r8);
    uc_reg_write(g_x64_uc, UC_X86_REG_R9, &g_x64_reg.reg.r_r9);
    uc_reg_write(g_x64_uc, UC_X86_REG_R10, &g_x64_reg.reg.r_r10);
    uc_reg_write(g_x64_uc, UC_X86_REG_R11, &g_x64_reg.reg.r_r11);
    uc_reg_write(g_x64_uc, UC_X86_REG_R12, &g_x64_reg.reg.r_r12);
        
    uc_reg_write(g_x64_uc, UC_X86_REG_R13, &g_x64_reg.reg.r_r13);
    uc_reg_write(g_x64_uc, UC_X86_REG_R14, &g_x64_reg.reg.r_r14);
    uc_reg_write(g_x64_uc, UC_X86_REG_R15, &g_x64_reg.reg.r_r15);
    
    }
    
    VOID x64_print_uc_registers()
    {
    
    printf("\n>--- --- --- %lld --- --- ---<\n", g_x64_instruction_count);
    
    printf("%#16llx:\t%s\t%s\n",g_x64_cs_insn[0].address,g_x64_cs_insn[0].mnemonic,g_x64_cs_insn[0].op_str);
    
    printf("rax=0x%16llx\n", g_x64_reg.reg.r_rax);
    printf("rcx=0x%16llx\n", g_x64_reg.reg.r_rcx);
    printf("rdx=0x%16llx\n", g_x64_reg.reg.r_rdx);
    printf("rbx=0x%16llx\n", g_x64_reg.reg.r_rbx);
    printf("rsp=0x%16llx\n", g_x64_reg.reg.r_rsp);
    
    printf("rbp=0x%16llx\n", g_x64_reg.reg.r_rbp);
    printf("rsi=0x%16llx\n", g_x64_reg.reg.r_rsi);
    printf("rdi=0x%16llx\n", g_x64_reg.reg.r_rdi);
    printf("rip=0x%16llx\n", g_x64_reg.reg.r_rip);
    printf("rfl=0x%16llx\n", g_x64_reg.reg.r_rflag);
    
    printf("r8 =0x%16llx\n", g_x64_reg.reg.r_r8);
    printf("r9 =0x%16llx\n", g_x64_reg.reg.r_r9);
    printf("r10=0x%16llx\n", g_x64_reg.reg.r_r10);
    printf("r11=0x%16llx\n", g_x64_reg.reg.r_r11);
    printf("r12=0x%16llx\n", g_x64_reg.reg.r_r12);
    
    printf("r13=0x%16llx\n", g_x64_reg.reg.r_r13);
    printf("r14=0x%16llx\n", g_x64_reg.reg.r_r14);
    printf("r15=0x%16llx\n", g_x64_reg.reg.r_r15);
    
    }
    
    
    VOID x64_print_uc_stack(DWORD64 rsp)
    {
    DWORD64 val = 0;
    
    for (ULONG i = 5; i > 0; i--)
    {
    uc_mem_read(g_x64_uc, (DWORD64)(rsp - i * 8), &val, sizeof(DWORD64));
    
    printf("\t|%16llx|\n", val);
    }
    
    uc_mem_read(g_x64_uc, (DWORD64)rsp, &val, sizeof(DWORD64));
    
    printf("===>    |%16llx|\n", val);
    
    for (ULONG i = 1; i < 5; i++)
    {
    uc_mem_read(g_x64_uc, (DWORD64)(rsp + i * 8), &val, sizeof(DWORD64));
    
    printf("\t|%16llx|\n", val);
    }
    }
    ```

    上述代码是模拟x86_64程序，这个cpu模拟器框架还支持arm,aarch64，mips，risc-v,risc-v 64等汇编模拟。后续还会给出模拟risc-v 64程序的步骤。

**学习过程中还有很多不足，还望朋友们指正！**
