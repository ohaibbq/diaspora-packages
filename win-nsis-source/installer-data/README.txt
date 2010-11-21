This is an experimental online, bundled installer 
for Diaspora/Ruby/Rails/MongoDB/ImageMagick

-------------------------------------------------

1. After installation is done, follow these instructions:

	1.1 	
	   Copy 
	     root\opt\diaspora\config\app_config.yml.example
	   To
	     app_config.yml in the same dir

	1.2
	   Edit this with your favorite windows editor (Notepad?)
	   pod_url: should be your external hostname

        1.3
	   If you intend to use it on the internet, make sure your router
	   has port 3000 and 8080 forwarded (8080 is for the websocket/pod2pod comm)

	1.4
	   Rock on!!

2. What does this package contain
	Q: What is lots of stuff?
	A:  
		*  Ruby 1.8.7-p302 (http://rubyinstaller.org/downloads/)
		*  DevKit-4.5.0-20100819-1536-sfx.exe (http://rubyinstaller.org/downloads/)
		*  PortableGit-1.7.3.1-preview20101002.7z (http://msysgit.googlecode.com/files/PortableGit-1.7.3.1-preview20101002.7z)
		*  mongodb-win32-i386-1.6.3.zip (http://fastdl.mongodb.org/win32/mongodb-win32-i386-1.6.3.zip)
		*  custom made patch by me (hopefully working!)

3. Q: It's not working
   A: This windows installer is an experiment, but someone in #diaspora-dev@freenode might be able to help you out