require 'openssl'
require 'fileutils'

OLDSTRING = "net.sourceforge.iTerm"
NEWSTRING = "com.googlecode.iterm2"
OLDSHA1 = "c11b78e31281b76155cadc5cf96df002030f0c2a"
NEWSHA1 = "5411880a77b54dd9a2cb135f89a2f7c4f400b347"

#The argument to the script should be the location of OpenTerminal.app

#To build the path of the executable to patch
app_dir = ""					#Path to OpenTerminal.app
bin_dir = "Contents/MacOS/"
binary = "OpenTerminal"
target = ""						# app_dir + bin_dir + binary

if ARGV.size == 1 then
	app_dir += ARGV[0]
	app_dir += '/' unless target.end_with?('/')
	target += app_dir + bin_dir + binary
else
	puts "This application will patch OpenTerminal version 2.07 to make it compatible with iTerm2. Please drag OpenTerminal onto the OpenTerminalPatch icon or this window."
	exit(-1)
end

puts "OpenTerminal specified: #{app_dir}"

#Check that the file exists
if !(app_dir.end_with?(".app/") && Dir.exist?(app_dir)) then
	puts app_dir + " not found or not a proper application. Please drag OpenTerminal onto the OpenTerminalPatch icon."
	exit(-1)
elsif !Dir.exist?(app_dir + bin_dir) then
	puts bin_dir + " directory not found in " + app_dir + ". OpenTerminal may be corrupt."
	exit(-1)
elsif !File.exist?(target) then
	puts "Binary #{binary} not found in #{app_dir}. OpenTerminal may be corrupt."
	exit(-1)
end

#Check if the backup exists. Restore, if so (this is how to revert.)
bkup = target + ".bkup"
if File.exist?(bkup) && OpenSSL::Digest::SHA1.new(File.read(bkup)) == OLDSHA1 then
	puts "A backup of the old OpenTerminal exists. It will be restored. Run the patch again to re-apply it."
	FileUtils.mv(bkup, target)
	exit(0)
end

#Check version
shasum = OpenSSL::Digest::SHA1.new(File.read(target)).to_s
if shasum == OLDSHA1 then
	puts "Now patching OpenTerminal version 2.07..."
elsif shasum == NEWSHA1 then
	puts "OpenTerminal already patched! Click Quit to exit."
	exit(1)
else
	puts "OpenTerminal exists, but the binary is either corrupt or not version 2.07. Click Quit to exit."
	exit(-1)
end

#Otherwise, continue with the patch.
FileUtils.cp(target, target + ".bkup")

#Get the program as a string, make the change
program = File.read(target, mode:"rb")
patch = program.sub!(OLDSTRING, NEWSTRING)
if patch == nil then
	raise "Tried to patch, but I didn't the item to patch... Click Quit to exit."
end

#Write to the file
File.write(target, patch)

#Check the shasum.  If not new, then revert the backup...
result = 0
shasum = OpenSSL::Digest::SHA1.new(File.read(target)).to_s
if shasum == NEWSHA1 then
	puts "OpenTerminal successfully patched!  Now cleaning up..."
	puts "Run OpenTerminalPatch again to revert changes."
	result = 0
else
	puts "OpenTerminal was not successfully patched...  Attempting to revert."
	FileUtils.cp(target + ".bkup", target)
	result = -1
end

#FileUtils.rm(target + ".bkup")		#Remove the backup. Eh, why not keep it...
FileUtils.chmod(0755, target)		#Make executable
puts "You may click Quit to exit."
exit(result)