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

# Some initializations:
[ "$DESTDIR" ] || DESTDIR=
[ "$JAVA_CLASSPATH" ] || JAVA_CLASSPATH=


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
    sun_java="/usr/lib/jvm/java-6-sun /usr/lib/jvm/java-1.5.0-sun /usr/lib/j2sdk1.4-sun /usr/lib/j2*1.[456]-sun"
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
	java_debug "Using already set JAVA_CMD = $JAVA_CMD"
	return 0;		# Nothing to do
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
	    sun6) DIRS=/usr/lib/jvm/java-6-sun
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
    fi
    if [ "$JAVA_HOME" ] ; then
	if [ "$JAVA_DEBUGGER" ] && [ -x "$JAVA_HOME/bin/jdb" ]; then
	    JAVA_CMD="$JAVA_HOME/bin/jdb"
	else
	    JAVA_CMD="$JAVA_HOME/bin/java"
	fi
	java_debug "Found JAVA_HOME = $JAVA_HOME"
	java_debug "Found JAVA_CMD = $JAVA_CMD"
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

# Find jars and add them to the classpath
find_jars() {
    looked_for_jars=1
    for jar in $@ ; do
	if [ -r $DESTDIR/usr/share/java/$jar ]; then
	    JAVA_CLASSPATH=$JAVA_CLASSPATH:$DESTDIR/usr/share/java/$jar
	elif [ -r $DESTDIR/usr/share/java/$jar.jar ]; then 
	    JAVA_CLASSPATH=$JAVA_CLASSPATH:$DESTDIR/usr/share/java/$jar.jar
	else
	    java_warning "Unable to locate $jar in $DESTDIR/usr/share/java/"
	fi
    done
}

# Adds the first jar found to the classpath. Useful for alternative
# dependencies.
find_one_jar_in() {
    looked_for_jars=1
    for jar in $@ ; do
	if [ -r $DESTDIR/usr/share/java/$jar ]; then
	    JAVA_CLASSPATH=$JAVA_CLASSPATH:$DESTDIR/usr/share/java/$jar
	    return 0
	elif [ -r $DESTDIR/usr/share/java/$jar.jar ]; then 
	    JAVA_CLASSPATH=$JAVA_CLASSPATH:$DESTDIR/usr/share/java/$jar.jar
	    return 0
	fi
    done
    java_warning "Could fine none of $@ in $DESTDIR/usr/share/java/"
    return 1
}

# Runs the program !
run_java() {
    if [ -z "$JAVA_CMD" ]; then
	java_warning "No JAVA_CMD set for run_java, using JAVA_CMD = java"
	JAVA_CMD=java
    fi
    if [ "$FORCE_CLASSPATH" ]; then
	java_debug "Using unmodified classpath : $FORCE_CLASSPATH";
	cp="-classpath $FORCE_CLASSPATH";
    elif [ "$JAVA_CLASSPATH" ]; then
	cp="-classpath $JAVA_CLASSPATH";
    else
	cp="";
    fi
    java_debug "Runnning $JAVA_CMD $JAVA_ARGS $cp $@"
    exec $JAVA_CMD $JAVA_ARGS $cp "$@"
}

# Runs a java jar.
# You don't have to use this function.
run_jar() {
    if [ "$looked_for_jars" ]; 
	java_warning "It is most likely useless to use find_jar when running"
	java_warning "a class with run_jar (-classpath is ignored)"
    fi
    run_java -jar "$@"
}