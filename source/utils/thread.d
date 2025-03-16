module atlant.utils.thread;

import core.sys.posix.pthread;

struct Thread
{
    pthread_t thread;
    int result;

    extern(C) this(void* function(void*) fn, void* data)
    {
        result = pthread_create(&thread, null, fn, data);
    }

    int join()
    {
        return pthread_join(thread, null);
    }

    int detach()
    {
        return pthread_detach(thread);
    }
}
