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

void parseArgs(Configuration* conf, int argc, char** argv)
{
	enum Option
	{
		None,
		WorkingDirectory,
		// Option,
		// HttpBindAddress,
		Port
		// AddIndex
	};

	Option next = Option.None;
	bool nextValue = false;
	import core.stdc.stdlib: exit;
	import core.stdc.string;
	import core.stdc.stdio;

	for (int i = 1; i < argc; i++)
	{
		if (nextValue)
		{
			if (next == Option.WorkingDirectory)
			{
				String.cString(&conf.directory, argv[i]);
			}
			else if (next == Option.Port)
			{
				import core.stdc.stdlib;
				conf.port = atoi(argv[i]);
			}
			next = Option.None;
			nextValue = false;
			continue;
		}

		if (strcmp("--help", argv[i]) == 0 || strcmp("-h", argv[i]) == 0)
		{
			printf("Use: %s [OPTIONS]\n", argv[0]);
			printf("-p, --port - specify HTTP PORT\n");
			printf("-w, --working-directory - set application root directory\n");
			exit(0);
		}

		if (strcmp("--working-directory", argv[i]) == 0 || strcmp("-w", argv[i]) == 0)
		{
			nextValue = true;
			next = Option.WorkingDirectory;
		}

		if (strcmp("--port", argv[i]) == 0 || strcmp("-p", argv[i]) == 0)
		{
			nextValue = true;
			next = Option.Port;
		}
	}

	if (nextValue)
	{
		printf("Specify value of %s\n", argv[argc-1]);
		exit(0);
	}
}
