
all: 
	gunzip cn/narrativeLevel.mod.gz
	gunzip cn/segmentation.mod.gz
	gunzip cn/subjectivity.mod.gz
	gunzip cn/wsegcombo.mod.gz
	gunzip en/narrativeLevel.mod.gz
	gunzip en/segmentation.mod.gz
	gunzip en/subjectivity.mod.gz
	gunzip en/swb.tagmod.gz
	gunzip fa/narrativeLevel.mod.gz
	gunzip fa/paths.gz
	gunzip fa/segmentation.mod.gz
	gunzip fa/subjectivity.mod.gz

compact:
	gzip cn/narrativeLevel.mod
	gzip cn/segmentation.mod
	gzip cn/subjectivity.mod
	gzip cn/wsegcombo.mod
	gzip en/narrativeLevel.mod
	gzip en/segmentation.mod
	gzip en/subjectivity.mod
	gzip en/swb.tagmod
	gzip fa/narrativeLevel.mod
	gzip fa/paths
	gzip fa/segmentation.mod
	gzip fa/subjectivity.mod

