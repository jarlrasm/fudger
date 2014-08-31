# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'lib/fudger_version'

spec = Gem::Specification.new do |s|
  s.name = 'Fudger'
  s.version = FUDGER_VERSION
  s.has_rdoc = false
  s.extra_rdoc_files = ['README', 'LICENSE']
  s.summary = 'A small GM tool for Fudge and Gurps Lite'
  s.description = s.summary
  s.author = 'Sveinung F.'
  s.email = ''
  s.rubyforge_project = 'fudger'
  s.homepage='http://fudger.rubyforge.org'
  s.executables = ['fudger']
  s.files = %w(LICENSE README Rakefile bin/fudger share/applications/fudger.desktop
 share/mime-info/fudger.mime share/mime-info/fudger.keys share/application-registry/fudger.application 
share/icons/gnome/48x48/apps/fudger.png share/icons/gnome/48x48/mimetypes/gnome-mime-text-fudger-campaign.png 
lib/rules/fudge.xml lib/rules/gurps_lite.xml lib/rules/systemless.xml lib/rules/starwarsd6.xml
 lib/ui/fudger-gtk/fudger.ui lib/ui/fudger-swing/fudger_swing_ui.jar share/locale/nb/LC_MESSAGES/fudger.mo share/locale/nb/LC_MESSAGES/fudger_ui.mo)+
    Dir.glob("lib/stylesheets/*.css")+Dir.glob("lib/images/*.png")+Dir.glob("lib/doc/*.png")+
    Dir.glob("lib/doc/*.html")+Dir.glob("lib/*.rb")+Dir.glob("lib/plugins/*.rb")+Dir.glob("lib/ui/fudger-gtk/*.rb")+
    Dir.glob("lib/report templates/default/default*")+Dir.glob("lib/report templates/fudge/fudge*")+Dir.glob("lib/report templates/gurps lite/gurps lite*")+Dir.glob("lib/report templates/star wars d6/star wars d6*")+
    Dir.glob("lib/ui/fudger-swing/*.rb")+Dir.glob("lib/names/*.yml")+ Dir.glob("{test,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end
rule '.mo' => ['.po'] do |t|
    sh "rmsgfmt #{t.source} -o #{t.name}"
end

rule 'fudger.po' => ['share/locale/fudger.pot'] do |t|
  puts t.source
  sh "msgmerge #{t.name} #{t.source} -U"
end
rule 'fudger_ui.po' => ['share/locale/fudger_ui.pot'] do |t|
  puts t.source
  sh "msgmerge #{t.name} #{t.source} -U"
end

file 'share/locale/fudger.pot' => Dir.glob('lib/*.rb') do
  rm "share/locale/fudger.pot" unless !File.exists?("share/locale/fudger.pot")
  sh "rgettext lib/*.rb -o share/locale/fudger.pot"
end
file 'share/locale/fudger_ui.pot' => ["lib/ui/fudger-gtk/fudger.ui"] do
  rm "share/locale/fudger_ui.pot" unless !File.exists?("share/locale/fudger_ui.pot")
  sh "xgettext lib/ui/fudger-gtk/fudger.ui --language=Glade --keyword=col -o share/locale/fudger_ui.pot"
end
file 'lib/doc/index.html' => ["lib/doc/fudger.docbook"] do
  sh "docbook2html lib/doc/fudger.docbook -o lib/doc"
end
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end
task :translations => ['share/locale/nb/LC_MESSAGES/fudger.mo', 'share/locale/nb/LC_MESSAGES/fudger_ui.mo']
task :doc => ['lib/doc/index.html']

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end
