# RISC-V 大作业 说明文档

## 1.简介

本次大作业使用verilog硬件描述语言实现了一个基于RISC-V架构，rv32i指令集的cpu。

本次作业实现了五级流水、I-Cache、D-Cache、naive分支预测和65MHz上板。

![architecture](./archiarchitecture.png)

## 2.模块说明

- stage_if & i_cache：完成取指令工作。
  
  - 若cache hit，则一个周期取回指令，最理想情况下CPI=1。若cache miss，则要6个周期取回一条指令。
  
  - 如果收到跳转信号，停止当前的取指令开始从跳转的位置取新指令。
  
  - 如果和stage_mem的访存操作产生Structural Hazard，那么会让stage_mem的访存操作先执行，自己进入等待状态。
  
  - 在gcd的模拟测试中，一共有1260次访问i_cache，hit次数为897次，miss rate为28.8%

- stage_id：完成译码和判断分支的工作。
  
  - 这里我的naive分支预测是每次都判断分支不跳转，如果跳转了会给ctrl发信号让ctrl控制stage_if跳转。
  
  - 接受来自stage_exe和stage_mem的数据转发。注意，即使有转发，在一个load指令经过stage_exe的时候也可能会出现Data Hazard。这个时候ctrl要把译码阶段给锁住。

- stage_exe：完成算术逻辑运算。
  
  - 这个模块不需要考虑Hazard，比较简单。

- stage_mem & d_cache：完成内存读写工作。
  
  - 对Store指令，要花5周期写入一个word。对Load指令，要花6周期读回一个word。如果cache hit，我们只要两周期就可以得到一个word。
  
  - 在gcd的模拟测试中，一共有31次访问d_cache，hit次数为23次，miss rate为25.8%

- mcu：stage_if和stage_mem的内存访问选择器
  
  - 接受来自stage_if和stage_mem的内存访问请求，为避免内存的Structural Hazard，只允许一个模块的访存请求通过。
  
  - stage_mem的访存优先级高于stage_if。

- ctrl：控制跳转、流水线暂停。
  
  - 接受来自stage_id的跳转信息，判断跳转信息有效后控制取指令阶段跳转。
  
  - 接受来自stage_id的数据请求信息，判断会产生Data Hazard后控制译码阶段暂停。
  
  - 接受来自mcu的访存信息，判断访存阶段正在工作后控制流水线暂停。

- regfile：寄存器

- if_id & id_exe & exe_mem &mem_wb：锁存器
  
  - 接受来自ctrl的stall信息。如果前一个阶段暂停而后一个阶段没暂停，需要向后一个阶段传空指令。如果两个阶段都暂停，则什么都不做，如果两个阶段都没暂停，则从前一个阶段向后一个阶段传递数据。
  
  - mem_wb实现向regfile写回的功能。
