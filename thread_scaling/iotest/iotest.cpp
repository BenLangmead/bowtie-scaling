//
//  iotest.cpp
//  iotest
//
//  Created by Ben Langmead on 11/14/17.
//  Copyright © 2017 Ben Langmead. All rights reserved.
//

#include <iostream>
#include <sstream>
#include <string>
#include <cstring>
#include <cstdlib>
#include <iomanip>
#include <limits>
#include <getopt.h>
#include <sys/time.h>
#include "iotest.hpp"

using namespace std;

/**
 * Vary:
 * 1. Buffer size: start, stride, end
 * 2. Output file name
 */

static long lo    =              256 * 1024;
static long hi    =         8 * 1024 * 1024;
static long step  =              256 * 1024;
static long bytes = 4L * 1024 * 1024 * 1024;
static string output_fn = "/tmp/iotest.tmp";

static const char *short_options = "h:l:s:b:o:";

static struct option long_options[] = {
	{(char*)"hi",     required_argument,  0, 'h'},
	{(char*)"lo",     required_argument,  0, 'l'},
	{(char*)"step",   required_argument,  0, 's'},
	{(char*)"bytes",  required_argument,  0, 'b'},
	{(char*)"output", required_argument,  0, 'o'},
	{(char*)0,        0,                  0, 0} //  terminator
};

/**
 * Print a summary usage message to the provided output stream.
 */
static void printUsage(ostream& out) {
	cerr
	<< " Input:" << endl
	<< "  -h/--hi       max buffer/block size to try" << endl
	<< "  -l/--lo       min buffer/block size to try" << endl
	<< "  -s/--step     step buffer/block size by this much" << endl
	<< "  -b/--bytes    total # bytes to write" << endl
	<< "  -o/--putput   output file" << endl
	;
}

static long parseInt(long lower, long upper, const char *errmsg, const char *arg) {
	long l;
	char *endPtr= NULL;
	l = strtol(arg, &endPtr, 10);
	if (endPtr != NULL) {
		if (l < lower || l > upper) {
			cerr << errmsg << endl;
			printUsage(cerr);
			throw 1;
		}
		return l;
	}
	cerr << errmsg << endl;
	printUsage(cerr);
	throw 1;
	return -1;
}

static long parseInt(long lower, const char *errmsg, const char *arg) {
	return parseInt(lower, std::numeric_limits<long>::max(), errmsg, arg);
}

static void parseOption(int next_option, const char *arg) {
	switch (next_option) {
		case 'l': {
			lo = parseInt(0, "-l arg must be positive", arg);
			break;
		}
		case 'h': {
			hi = parseInt(0, "-h arg must be positive", arg);
			break;
		}
		case 's': {
			step = parseInt(0, "-s arg must be positive", arg);
			break;
		}
		case 'b': {
			bytes = parseInt(0, "-b/--bytes arg must be positive", arg);
			break;
		}
		case 'o': {
			output_fn = string(arg);
			break;
		}
		default: {
			printUsage(cerr);
			throw 1;
		}
	}
}

/**
 * Read command-line arguments
 */
static void parseOptions(int argc, const char **argv) {
	int option_index = 0;
	int next_option;
	while(true) {
		next_option = getopt_long(argc, const_cast<char**>(argv),
								  short_options, long_options, &option_index);
		const char * arg = optarg;
		if(next_option == EOF) {
			break;
		}
		parseOption(next_option, arg);
	}
}

static FILE *open() {
	FILE *ofh = NULL;
	ofh = fopen(output_fn.c_str(), "wb");
	if(ofh == NULL) {
		cerr << "Could not open \"" << output_fn << "\" for writing"
		     << endl;
		throw 1;
	}
	return ofh;
}

const char *msg = "This is a nice short message but not too short.  It's kind of a medium sized message.\n";

static void fwrite_no_setvbuf() {
	FILE *ofh = open();
	size_t tot_written = 0;
	const size_t stlen = strlen(msg);
	while(tot_written < bytes) {
		size_t ret = fwrite(msg, stlen, 1, ofh);
		if(ret != 1) {
			cerr << "Return value from fwrite was " << ret << endl;
			throw 1;
		}
		tot_written += stlen;
	}
	fclose(ofh);
}

/**
 * Does it matter how many calls to fwrite we make?
 */
static void fwrite_setvbuf(long buffer_size) {
	FILE *ofh = open();
	char *buf = new char[buffer_size];
	if(setvbuf(ofh, buf, _IOFBF, buffer_size)) {
		cerr << "Warning: Could not allocate the proper buffer size for "
		<< "output file stream. " << endl;
		throw 1;
	}
	size_t tot_written = 0;
	const size_t stlen = strlen(msg);
	while(tot_written < bytes) {
		size_t ret = fwrite(msg, stlen, 1, ofh);
		if(ret != 1) {
			cerr << "Return value from fwrite was " << ret << endl;
			throw 1;
		}
		tot_written += stlen;
	}
	delete[] buf;
	fclose(ofh);
}

/**
 * Run appropriate dd command.
 *
 * dsync: "use synchronized I/O for data"
 * sync: "likewise, but also for metadata"
 * fdatasync: "physically write output file data before finishing"
 * fsync: "likewise, but also write metadata"
 */
static void dd(long block_size, bool dsync) {
	ostringstream cmd_ss;
	cmd_ss << "dd if=/dev/zero of=" << output_fn
	       << " bs=" << block_size
	       << " count=" << (bytes / block_size)
	       << " 2>/dev/null";
	if(dsync) {
		cmd_ss << " oflag=dsync";
	} else {
		cmd_ss << " conv=fdatasync";
	}
	//cerr << "dd cmd: " << cmd_ss.str() << endl;
	int ret = system(cmd_ss.str().c_str());
	if(ret != 0) {
		cerr << "Exitlevel from dd is " << ret << endl;
		throw 1;
	}
}

/* Subtract the ‘struct timeval’ values X and Y, storing the result in RESULT.
 Return 1 if the difference is negative, otherwise 0.
 Borrowed from: https://www.gnu.org/software/libc/manual/html_node/Elapsed-Time.html
 */
static inline bool timeval_subtract(timeval& result, const timeval& xin, const timeval& yin) {
	/* Perform the carry for the later subtraction by updating y. */
	timeval x = xin;
	timeval y = yin;
	if (x.tv_usec < y.tv_usec) {
		int nsec = (y.tv_usec - x.tv_usec) / 1000000 + 1;
		y.tv_usec -= 1000000 * nsec;
		y.tv_sec += nsec;
	}
	if (x.tv_usec - y.tv_usec > 1000000) {
		int nsec = (x.tv_usec - y.tv_usec) / 1000000;
		y.tv_usec += 1000000 * nsec;
		y.tv_sec -= nsec;
	}
	
	/* Compute the time remaining to wait. tv_usec is certainly positive. */
	result.tv_sec = x.tv_sec - y.tv_sec;
	result.tv_usec = x.tv_usec - y.tv_usec;
	
	/* Return 1 if result is negative. */
	return x.tv_sec < y.tv_sec;
}

/**
 * Use gettimeofday() call to keep track of elapsed time between creation and
 * destruction.  If verbose is true, Timer will print a message showing
 * elapsed time to the given output stream upon destruction.
 */
class Timer {
public:
	Timer(ostream& out = cout, const char *msg = "", bool verbose = true) :
	_t(), _out(out), _msg(msg), _verbose(verbose)
	{
		gettimeofday(&_t, NULL);
	}
	
	/// Optionally print message
	~Timer() {
		if(_verbose) write(_out);
	}
	
	/// Return elapsed time since Timer object was created
	time_t elapsed() const {
		timeval f;
		gettimeofday(&f, NULL);
		return f.tv_sec - _t.tv_sec;
	}
	
	void write(ostream& out) {
		timeval f;
		gettimeofday(&f, NULL);
		timeval diff;
		timeval_subtract(diff, f, _t);
		time_t hours   = (diff.tv_sec / 60) / 60;
		time_t minutes = (diff.tv_sec / 60) % 60;
		time_t seconds = (diff.tv_sec % 60);
		time_t milliseconds = (diff.tv_usec / 1000);
		std::ostringstream oss;
		oss << _msg << setfill ('0') << setw (2) << hours << ":"
		    << setfill ('0') << setw (2) << minutes << ":"
		    << setfill ('0') << setw (2) << seconds << "."
		    << setfill ('0') << setw (3) << milliseconds;
		out << oss.str().c_str();
	}
	
private:
	timeval     _t;
	ostream&    _out;
	const char *_msg;
	bool        _verbose;
};

int main(int argc, const char **argv) {
	parseOptions(argc, argv);
	for(long i = lo; i <= hi; i += step) {
		cout << i;
		{
			Timer t1(cout, ",");
			fwrite_no_setvbuf();
		}
		{
			Timer t2(cout, ",");
			fwrite_setvbuf(i);
		}
		//{
		//	Timer t3(cout, "dd_dsync: ");
		//	dd(i, true);
		//}
		{
			Timer t4(cout, ",");
			dd(i, false);
		}
		cout << endl;
	}
	return 0;
}
