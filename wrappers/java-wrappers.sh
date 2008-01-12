# wrappers.sh: various functions to be used by Java script wrappers
# Copyright 2008 by Vincent Fourmond <fourmond@debian.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# Display a debugging message
java_debug() {
    if [ "$DEBUG_WRAPPER" ]; then
	echo "[debug] $0: $@" >&2;
    fi
}

# Displays a warning
java_warning() {
    echo "[warning] $0: $@" >&2;
}

# Exit with an error message
java_fail() {
    echo "[error] $0: $@" >&2;
    exit 1;
}

# Some initializations:
if [ "$JAVA_CLASSPATH" ]; then
    java_debug "Building classpath on JAVA_CLASSPATH = '$JAVA_CLASSPATH'"
else
    JAVA_CLASSPATH=
fi
if [ "$DESTDIR" ]; then
    java_debug "Using DESTDIR = '$DESTDIR'"
else
    DESTDIR=""
fi

if [ "$JAVA_JARPATH" ]; then
    java_debug "Jar lookup is done in JAVA_JARPATH = '$JAVA_JARPATH'"
else
    JAVA_JARPATH=$DESTDIR/usr/share/java
fi


# Try to find a Java runtime and set JAVA_HOME and JAVA_CMD accordingly.
# If JAVA_CMD exists, nothing is done. If JAVA_HOME exists, only that
# is searched.
#
# In the other cases, the runtime is looked for according to one of the
# following arguments:
#  * 2 : java runtime 2 
#  * swing : a JVM that has swing
#  * fullxml: a JVM that has all XML classes, including
#    javax.xml.stream.util.StreamReaderDelegate
#  * sun: sun's JVM, for stuff depending on the infamous com.sun classes
#  * sun6: sun's JVM version 6
#
# If JAVA_DEBUGGER is set, we try to use jdb rather than java, if it is
# present.
#
# This information is currently *far from complete* !!!
find_java_runtime() {
    # First, known runtimes:

    sun5="/usr/lib/jvm/java-1.5.0-sun /usr/lib/j2*1.5-sun"
    sun4="/usr/lib/j2*1.4-sun"
    sun6="/usr/lib/jvm/java-6-sun /usr/lib/j2*1.6-sun"
    
    sun_java="$sun4 $sun5 $sun6"
    
    gcj2="/usr/lib/jvm/java-*-gcj-4.* "
    sablevm="/usr/lib/sablevm"
    kaffe="/usr/lib/kaffe /usr/lib/kaffe/pthreads /usr/lib/kaffe/jthreads"
    icedtea="/usr/lib/jvm/java-7-icedtea"
    cacao="/usr/lib/jvm/cacao"

    # IBM, coming from argouml.sh
    ibm="/usr/lib/j2*1.[456]-ibm"

    # Then, classes of JVM:
    all_runtimes="$gcj2 $cacao $sablevm $kaffe $icedtea $sun_java $ibm /usr/lib/jvm/*"

    # Java2 runtimes:
    java2_runtimes="$gcj2 $iced_tea $sun_java $ibm"

    # Full swing runtimes:
    full_swing_runtimes="$iced_tea $sun_java $ibm"

    # Sun java apparently has some XML functions more than concurrents:
    xml_extra="/usr/lib/jvm/java-6-sun /usr/lib/jvm/java-1.5.0-sun"

    if [ "$JAVA_CMD" ]; then
	if which "$JAVA_CMD" > /dev/null; then
	    java_debug "Using already set JAVA_CMD = '$JAVA_CMD' => '"`which "$JAVA_CMD"`"'"
	    return 0;		# Nothing to do
	else
	    java_warning "JAVA_CMD was set to '$JAVA_CMD', but which(1) does not find it."
	    java_warning "Therefore ignoring JAVA_CMD"
	fi
    fi

    if [ -z "$JAVA_BINDIR" ]; then 
	if [ "$JAVA_DEBUGGER" ] && [ -x "$JAVA_BINDIR/jdb" ]; then
	    JAVA_CMD="$JAVA_BINDIR/jdb"
	elif [ -x "$JAVA_BINDIR/java" ]; then
	    JAVA_CMD="$JAVA_BINDIR/java"
	fi
	if [ "$JAVA_CMD" ]; then
	    java_debug "Using '$JAVA_CMD' from JAVA_BINDIR = '$JAVA_BINDIR'"
	    return 0;
	else
	    java_warning "JAVA_BINDIR = '$JAVA_BINDIR' does not point to a java binary"
	fi
    fi

    if [ -z "$JAVA_HOME" ]; then
        # We now try to look for a reasonable JAVA_HOME.
        # First, narrow the choices, approximately according to what
        # was asked
	case $1 in
	    # A java2 runtime
	    2) DIRS=$java2_runtimes
		;;
	    swing) DIRS="$icedtea $sun_java";
		;;
	    sun) DIRS=$sun_java
		;;
	    sunmax5) DIRS="$sun4 $sun5"
		;;
	    sunmin5) DIRS="$sun5 $sun6"
		;;
	    sun6) DIRS=$sun6
		;;
	    fullxml) DIRS=$xml_extra
		;;
	    *) DIRS=$all_runtimes
		;;
	esac
        # And pick up the first one that works
	for dir in $DIRS; do
	    if [ -x $dir/bin/java ]; then
		JAVA_HOME=$dir
		break;
	    fi
	done
    else
	java_debug "Using provided JAVA_HOME = '$JAVA_HOME'"
    fi
    if [ "$JAVA_HOME" ] ; then
	if [ "$JAVA_DEBUGGER" ] && [ -x "$JAVA_HOME/bin/jdb" ]; then
	    JAVA_CMD="$JAVA_HOME/bin/jdb"
	else
	    JAVA_CMD="$JAVA_HOME/bin/java"
	fi
	java_debug "Found JAVA_HOME = '$JAVA_HOME'"
	java_debug "Found JAVA_CMD = '$JAVA_CMD'"
	return 0		# Fine
    else
	java_warning "No java runtime was found for flavor '${1:-none}'"
	return 1;
    fi
}

# Same as find_java_runtime, but fails with an error if
# nothing is found.
require_java_runtime() {
    find_java_runtime "$@" || \
	java_fail "Unable to find an appropriate java runtime. See java_wrappers(7) for help"
}

# Looks for a jar file and returns its location as the
# found_jar variable, or fails if no jar was found.
locate_jar() {
    jar="$1"
    if [ -r $JAVA_JARPATH/$jar ]; then
	found_jar=$JAVA_JARPATH/$jar
    elif [ -r $JAVA_JARPATH/$jar.jar ]; then
	found_jar=$JAVA_JARPATH/$jar.jar
    elif [ -r $jar ]; then
	# Maybe issue a warning that jars should not be looked
	# for absolutely ?
	found_jar=$JAVA_JARPATH/$jar
    elif [ -r $jar.jar ]; then
	# Maybe issue a warning that jars should not be looked
	# for absolutely ?
	found_jar=$JAVA_JARPATH/$jar.jar
    else
	return 1		# Not found
    fi
    return 0			# Found
}

# Find jars and add them to the classpath
find_jars() {
    looked_for_jars=1
    for jar in $@ ; do
	if locate_jar $jar; then
	    JAVA_CLASSPATH=$JAVA_CLASSPATH:$found_jar
	else
	    java_warning "Unable to locate $jar in $JAVA_JARPATH"
	fi
    done
}

# Adds the first jar found to the classpath. Useful for alternative
# dependencies.
find_one_jar_in() {
    looked_for_jars=1
    for jar in $@ ; do
	if locate_jar $jar; do 
	    JAVA_CLASSPATH=$JAVA_CLASSPATH:$found_jar
	    return 0
	fi
    done
    java_warning "Could fine none of $@ in $JAVA_JARPATH"
    return 1
}

# Runs the program !
run_java() {
    if [ -z "$JAVA_CMD" ]; then
	java_warning "No JAVA_CMD set for run_java, falling back to JAVA_CMD = java"
	JAVA_CMD=java
    fi
    # We try to conjure up a JAVA_HOME from JAVA_CMD, if the former
    # is absent. Idea coming from bug #404728.
    if [ -z "$JAVA_HOME" ]; then
	full_cmd_path="$(readlink -f `which $JAVA_CMD`)"
	JAVA_HOME="${full_cmd_path:bin/*}"
	java_debug "Using JAVA_CMD to find JAVA_HOME = '$JAVA_HOME'"
    fi
    if [ "$FORCE_CLASSPATH" ]; then
	java_debug "Using imposed classpath : FORCE_CLASSPATH = '$FORCE_CLASSPATH'";
	cp="-classpath $FORCE_CLASSPATH";
    elif [ "$JAVA_CLASSPATH" ]; then
	cp="-classpath $JAVA_CLASSPATH";
    else
	cp="";
    fi
    # Exporting JAVA_HOME, I guess it can't hurt much, can it ?
    export JAVA_HOME
    java_debug "Environment variable CLASSPATH is '$CLASSPATH'"
    java_debug "Runnning $JAVA_CMD $JAVA_ARGS $cp $@"
    exec $JAVA_CMD $JAVA_ARGS $cp "$@"
}

# Runs a java jar.
# You don't have to use this function to run a jar, but you might find
# it useful, though.
run_jar() {
    if [ "$looked_for_jars" ]; 
	java_warning "It is most likely useless to use find_jar when running"
	java_warning "a class with run_jar (-classpath is ignored)"
    fi
    if locate_jar $1; then
	shift
	run_java -jar "$@"
    else
	java_fail "Unable to find jar $1 in $JAVA_JARPATH"
    fi
}