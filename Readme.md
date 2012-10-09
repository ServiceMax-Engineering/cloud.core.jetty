# Jetty Equinox Product Built with tycho and P2.

   ./start.sh

Configuration files inside ${jetty.home}/etc

# Dependencies

- Jetty: pulled from maven central
- Equinox: pulled from the eclispe-platform repository on eclipse.org
- Servlet Dependencies: pulled from eclipse-orbit repository on eclipse.org

# Build

    mvn clean package

The generated repository is inside cloud.core.jetty.repo/target/repository
The generated product assembly is inside cloud.core.jetty.repo/target/; it is cross-platform.

# Dual-Licensed: ASL-20 and Eclipse.


