vcs  :
	vcs  \
		-f filelist.f  \
		-timescale=1ns/1ps \
		-full64  -R  +vc  +v2k  -sverilog -debug_access+all\
		|  tee  vcs.log 
verdi  :
	verdi -f filelist.f -ssf tb.fsdb &
clean  :
	 rm  -rf  *~  core  csrc  simv*  vc_hdrs.h  ucli.key  urg* *.log  novas.* *.fsdb* verdiLog  64* DVEfiles *.vpd
