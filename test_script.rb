require 'redcarpet'
require 'byebug'
require 'rest-client'
require 'json'
require 'mathematical'

if ARGV.length < 3
  puts "Too few arguments"
  puts "Argument 1 must be the course id"
  puts "Argument 2 must be the type of lesson - page or assignment"
  puts "Argument 3 must be the name of the lesson"
  exit
end

ARGV.each do|a|
  puts "Argument: #{a}"
end

COURSE = ARGV[0]

if ARGV[1] != "page" || ARGV[1] != "assignment"
  ARGV[1] = "page"
end

ITEM = ARGV[1]
NAME = ARGV[2]



def git_co_master
  cmd = "git co master"
  puts cmd
  `#{cmd}`
end

def git_pull
  cmd = "git pull"
  puts cmd
  `#{cmd}`
end

def git_add
  cmd = "git add ."
  puts cmd
  `#{cmd}`
end

def git_commit
  cmd = "git commit -m 'github-to-canvas automatic commit'"
  puts cmd
  `#{cmd}`
end

def git_push
  cmd = "git push"
  puts cmd
  `#{cmd}`
end

def git_remote
  cmd = "git config --get remote.origin.url"
  `#{cmd}`
end

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, options={tables: true, autolink: true, fenced_code_blocks: true})

if File.file?('./.canvas')
  puts '.canvas present'
else
  # git_co_master
  # git_pull
  remote = git_remote
  remote.gsub!("git@github.com:","https://raw.githubusercontent.com/")
  remote.gsub!(/.git$/,"")
  remote.strip!
  old_readme = File.read('README.md')

  # convert local images
  old_readme.gsub!(/\!\[.+\]\(.+\)/) {|image|
    if !image.match('amazonaws.com')
      image.gsub!(/\(.+\)/) { |path|
        path.delete_prefix!("(")
        path.delete_suffix!(")")
        "(" + remote + '/master/' + path + ")"
      }
    end
    image
  }

  old_readme.gsub!(/src=\"[\s\S]*?" /) { |img|
    img.gsub!(/\"/, "")
    img.gsub!(/src=/, '')
    img.strip!
    'src="' + remote + '/master/' + img + '"'
  }
  
  new_readme = markdown.render(old_readme)
  renderer = Mathematical.new({format: :png})
  tex_png_index = 0
  # latex_array = new_readme.scan(/\$.+\$/)
  new_readme.gsub!(/\$\$.+\$\$/) {|math|
    if !File.directory? 'assets'
      Dir.mkdir 'assets'
    end
    result = renderer.render(math)
    tex_png_index += 1
    puts tex_png_index
    File.write("./assets/#{tex_png_index}.png", result[:data])
    if !!result[:exception]
      puts ''
      puts ''
      puts '##############'
      puts ''
      puts 'Error Parsing LaTeX:'
      puts result[:data]
      puts ''
    end
    "<img src=\"#{remote}/master/assets/#{tex_png_index}.png\" />"
  }

  new_readme.gsub!(/\$.+\$/) {|math| 
    if !File.directory? 'assets'
      Dir.mkdir 'assets'
    end
    result = Mathematical.new.render(math)
    tex_png_index += 1
    puts tex_png_index
    File.write("./assets/#{math}.png", result[:data])
    if !!result[:exception]
      puts ''
      puts ''
      puts '##############'
      puts ''
      puts 'Error Parsing LaTeX:'
      puts result[:data]
      puts ''
    end
    "<img src=\"#{remote}/master/assets/#{tex_png_index}.png\" />"
  }

  git_add
  git_commit
  git_push
  
  File.write('./README.html', new_readme)
  byebug
  url = "https://learning.flatironschool.com/api/v1/courses/#{COURSE}/pages"
  payload = {
    'wiki_page[title]' => NAME,
    'wiki_page[body]' => new_readme,
    'wiki_page[editing_roles]' => "teachers" 
  }

  
  response = RestClient.post(url, payload, headers={
    "Authorization" => "Bearer #{ENV['CANVAS_API_KEY']}"
  })

  byebug
  puts 'hi'
end







