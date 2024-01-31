${executable}
output                  = ${logname}_$$(ProcId).out
error                   = ${logname}_$$(ProcId).err
log                     = ${logname}.log
initialdir              = ${rootfolder}/${folderName}
+JobFlavour             = "${queue}"
requirements            = (OpSysAndVer =?= "CentOS7")
periodic_remove         = JobStatus == 5  
WhenToTransferOutput    = ON_EXIT_OR_EVICT 
																
