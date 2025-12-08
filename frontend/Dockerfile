FROM ghcr.io/cirruslabs/flutter:stable AS build

#Set working directory
WORKDIR /app

#Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

#Get dependencies
RUN flutter pub get

#Copy the rest of the application
COPY . .

#Enable web support
RUN flutter config --enable-web

#Expose port
EXPOSE 3000

#Run the application
CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]