00010148 <main>:
   10148:	f7010113          	addi	sp,sp,-144
   1014c:	08112623          	sw	ra,140(sp)
   10150:	08812423          	sw	s0,136(sp)
   10154:	09010413          	addi	s0,sp,144
   10158:	fe042623          	sw	zero,-20(s0)
   1015c:	0300006f          	j	1018c <main+0x44>
   10160:	01e00713          	li	a4,30
   10164:	fec42783          	lw	a5,-20(s0)
   10168:	40f70733          	sub	a4,a4,a5
   1016c:	fec42783          	lw	a5,-20(s0)
   10170:	00279793          	slli	a5,a5,0x2
   10174:	ff040693          	addi	a3,s0,-16
   10178:	00f687b3          	add	a5,a3,a5
   1017c:	f8e7a223          	sw	a4,-124(a5)
   10180:	fec42783          	lw	a5,-20(s0)
   10184:	00178793          	addi	a5,a5,1
   10188:	fef42623          	sw	a5,-20(s0)
   1018c:	fec42703          	lw	a4,-20(s0)
   10190:	01d00793          	li	a5,29
   10194:	fce7d6e3          	ble	a4,a5,10160 <main+0x18>
   10198:	f7440793          	addi	a5,s0,-140
   1019c:	01e0i0593          	li	a1,30
   101a0:	00078513          	mv	a0,a5
   101a4:	020000ef          	jal	101c0 <sort>
   101a8:	00000793          	li	a5,0
   101ac:	00078513          	mv	a0,a5
   101b0:	08c12083          	lw	ra,140(sp)
   101b4:	08812403          	lw	s0,136(sp)
   101b8:	09010113          	addi	sp,sp,144
   101bc:	00008067          	ret

000101c0 <sort>:
   101c0:	fd010113          	addi	sp,sp,-48
   101c4:	02812623          	sw	s0,44(sp)
   101c8:	03010413          	addi	s0,sp,48
   101cc:	fca42e23          	sw	a0,-36(s0)
   101d0:	fcb42c23          	sw	a1,-40(s0)
   101d4:	fe042423          	sw	zero,-24(s0)
   101d8:	0cc0006f          	j	102a4 <sort+0xe4>
   101dc:	fe842783          	lw	a5,-24(s0)
   101e0:	fef42623          	sw	a5,-20(s0)
   101e4:	fe842783          	lw	a5,-24(s0)
   101e8:	00178793          	addi	a5,a5,1
   101ec:	fef42223          	sw	a5,-28(s0)
   101f0:	0440006f          	j	10234 <sort+0x74>
   101f4:	fec42783          	lw	a5,-20(s0)
   101f8:	00279793          	slli	a5,a5,0x2
   101fc:	fdc42703          	lw	a4,-36(s0)
   10200:	00f707b3          	add	a5,a4,a5
   10204:	0007a703          	lw	a4,0(a5)
   10208:	fe442783          	lw	a5,-28(s0)
   1020c:	00279793          	slli	a5,a5,0x2
   10210:	fdc42683          	lw	a3,-36(s0)
   10214:	00f687b3          	add	a5,a3,a5
   10218:	0007a783          	lw	a5,0(a5)
   1021c:	00e7d663          	ble	a4,a5,10228 <sort+0x68>
   10220:	fe442783          	lw	a5,-28(s0)
   10224:	fef42623          	sw	a5,-20(s0)
   10228:	fe442783          	lw	a5,-28(s0)
   1022c:	00178793          	addi	a5,a5,1
   10230:	fef42223          	sw	a5,-28(s0)
   10234:	fe442703          	lw	a4,-28(s0)
   10238:	fd842783          	lw	a5,-40(s0)
   1023c:	faf74ce3          	blt	a4,a5,101f4 <sort+0x34>
   10240:	fe842783          	lw	a5,-24(s0)
   10244:	00279793          	slli	a5,a5,0x2
   10248:	fdc42703          	lw	a4,-36(s0)
   1024c:	00f707b3          	add	a5,a4,a5
   10250:	0007a783          	lw	a5,0(a5)
   10254:	fef42023          	sw	a5,-32(s0)
   10258:	fe842783          	lw	a5,-24(s0)
   1025c:	00279793          	slli	a5,a5,0x2
   10260:	fdc42703          	lw	a4,-36(s0)
   10264:	00f707b3          	add	a5,a4,a5
   10268:	fec42703          	lw	a4,-20(s0)
   1026c:	00271713          	slli	a4,a4,0x2
   10270:	fdc42683          	lw	a3,-36(s0)
   10274:	00e68733          	add	a4,a3,a4
   10278:	00072703          	lw	a4,0(a4)
   1027c:	00e7a023          	sw	a4,0(a5)
   10280:	fec42783          	lw	a5,-20(s0)
   10284:	00279793          	slli	a5,a5,0x2
   10288:	fdc42703          	lw	a4,-36(s0)
   1028c:	00f707b3          	add	a5,a4,a5
   10290:	fe042703          	lw	a4,-32(s0)
   10294:	00e7a023          	sw	a4,0(a5)
   10298:	fe842783          	lw	a5,-24(s0)
   1029c:	00178793          	addi	a5,a5,1
   102a0:	fef42423          	sw	a5,-24(s0)
   102a4:	fe842703          	lw	a4,-24(s0)
   102a8:	fd842783          	lw	a5,-40(s0)
   102ac:	f2f748e3          	blt	a4,a5,101dc <sort+0x1c>
   102b0:	00000013          	nop (addi인데 imm이 0, rd=rs1)
   102b4:	02c12403          	lw	s0,44(sp)
   102b8:	03010113          	addi	sp,sp,48
   102bc:	00008067          	ret

