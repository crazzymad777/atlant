module atlant.utils.configuration;

import atlant.utils.string;

struct Configuration
{
	// bool defaultIndex;
	String directory;
	// bool enableDirectoryList;
	// bool lazyLoad;
	// bool defaultBindAddresses;
	int port;

	~this()
	{
		import core.stdc.stdlib;
		directory.drop();
	}
}

void* defaultConfiguration(Configuration* conf)
{
	import core.sys.posix.unistd: getcwd;
	conf.port = 8080;
	// conf.enableDirectoryList = true;
	// conf.lazyLoad = false;
	String.cString(&conf.directory, getcwd(null, 0));
	return conf;
}
