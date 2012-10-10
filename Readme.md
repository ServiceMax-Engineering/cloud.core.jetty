# Jetty Equinox Product Built with tycho and P2.

   ./start.sh

Configuration files inside ${jetty.home}/etc

# Dependencies

- Jetty: pulled from maven central
- Equinox: pulled from the eclispe-platform repository on eclipse.org
- Servlet Dependencies: pulled from eclipse-orbit repository on eclipse.org

# Build

    mvn clean package

The generated repository is inside org.intalio.eclipse.jetty.repo/target/repository
The generated product assembly is inside cloud.core.jetty.repo/target/; it is cross-platform.

# Dual-Licensed: ASL-20 and Eclipse.

# Equinox and Eclipse Orbit repository build

    mvn clean package -Pequinox

will produce org.intalio.eclipse.equinox.repo/target/repository
It contains equinox, p2, servlet and friends dependencies.
It also contains the bundles used by tycho test plugins: org.junit, org.eclipse.core.runtime, org.eclipse.ant.core and friends.

We use it as a drop-in replacements for eclipse-platform and eclipse-orbit for our own builds.

You can test that the equinox's repository is sufficient to build the jetty core product by executing:

    mvn clean package -Pequinox && mvn clean package -Pequinox-local

The second build will use the locally built repo to rebuild jetty.
