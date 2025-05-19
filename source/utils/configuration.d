module atlant.utils.configuration;

import atlant.utils.string;
import atlant.utils.list;

char* indexHtml = cast(char*) "index.html".ptr;
char* indexHtm = cast(char*) "index.htm".ptr;

struct Configuration
{
	String directory;
	List!(char*) listOfIndices;
	bool defaultIndex;
	// bool enableDirectoryList;
	// bool lazyLoad;
	List!(char*) listOfAddresses;
	bool defaultBindAddresses;
	int port;

	char* accesslog;
	char* pidfile;

	~this()
	{
		import core.stdc.stdlib;
		directory.drop();
	}
}

void* defaultConfiguration(Configuration* conf)
{
	import core.sys.posix.unistd: getcwd;
	conf.defaultIndex = true;
	conf.listOfIndices.add(indexHtml);
	conf.listOfIndices.add(indexHtm);
	conf.port = 8080;
	conf.defaultBindAddresses = true;
	// conf.enableDirectoryList = true;
	// conf.lazyLoad = false;
	String.cString(&conf.directory, getcwd(null, 0));
	conf.accesslog = null;
	conf.pidfile = null;
	return conf;
}

void parseArgs(Configuration* conf, int argc, char** argv)
{
	enum Option
	{
		None,
		WorkingDirectory,
		// Option,
		HttpBindAddress,
		Port,
		AddIndex,
		AccessLog,
		PidFile
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
			else if (next == Option.AddIndex)
			{
				if (conf.defaultIndex)
				{
					conf.defaultIndex = false;
					conf.listOfIndices.clear();
				}
				conf.listOfIndices.add(argv[i]);
			}
			else if (next == Option.HttpBindAddress)
			{
				if (conf.defaultBindAddresses)
				{
					conf.defaultBindAddresses = false;
				}
				conf.listOfAddresses.add(argv[i]);
			}
			else if (next == Option.AccessLog)
			{
				conf.accesslog = argv[i];
			}
			else if (next == Option.PidFile)
			{
				conf.pidfile = argv[i];
			}
			next = Option.None;
			nextValue = false;
			continue;
		}

		if (strcmp("--help", argv[i]) == 0 || strcmp("-h", argv[i]) == 0)
		{
			printf("Use: %s [OPTIONS]\n", argv[0]);
			printf("-a, --add-address - add bind address\n");
			printf("-p, --port - specify HTTP PORT\n");
			printf("-w, --working-directory - set application root directory\n");
			printf("-x, --add-index - define files which will be used as an index\n");
			printf("--access-log - specify access log file\n");
			printf("--pidfile - specify PID file\n");
			printf("--version - show version\n");
			exit(0);
		}

		if (strcmp("--add-address", argv[i]) == 0 || strcmp("-a", argv[i]) == 0)
		{
			nextValue = true;
			next = Option.HttpBindAddress;
		}

		if (strcmp("--add-index", argv[i]) == 0 || strcmp("-x", argv[i]) == 0)
		{
			nextValue = true;
			next = Option.AddIndex;
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

		if (strcmp("--access-log", argv[i]) == 0)
		{
			nextValue = true;
			next = Option.AccessLog;
		}

		if (strcmp("--pidfile", argv[i]) == 0)
		{
			nextValue = true;
			next = Option.PidFile;
		}

		if (strcmp("--version", argv[i]) == 0)
		{
			import atlant: PROGRAM_NAME, VERSION;
			printf("%s %s\n", PROGRAM_NAME.ptr, VERSION.ptr);
			exit(0);
		}

		if (nextValue == false)
		{
			fprintf(stderr, "Unrecognized option: %s\n", argv[i]);
		}
	}

	if (nextValue)
	{
		printf("Specify value of %s\n", argv[argc-1]);
		exit(0);
	}
}
