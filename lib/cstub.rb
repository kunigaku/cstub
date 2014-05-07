require "cstub/version"

require 'cast'
require 'optparse'

module Cstub
  def self.collect_types(ast)
    typelist = {}

    ast.entities.each do |node|
      node.Declaration? or next
      if node.type.Struct? && node.type.members
        if node.type.name
          typelist[node.type.name] = { value: "{0}" }
        end
      end
      if node.type.Enum? && node.type.members
        if node.type.name
          typelist[node.type.name] = { value: node.type.members[0].name }
        end
      end
      if node.typedef?
        node.declarators.each do |decl|
          if decl.type.Enum?
            typelist[decl.name] = { value: decl.type.members[0].name }
          end
          if decl.type.Int?
            typelist[decl.name] = { value: '0' }
          end
          if decl.type.Char?
            typelist[decl.name] = { value: '0' }
          end
          if decl.type.Float?
            typelist[decl.name] = { value: '0.0' }
          end
          if decl.type.Pointer?
            typelist[decl.name] = { value: 'NULL' }
          end
          if decl.type.Struct?
            typelist[decl.name] = { value: '{0}' }
          end
          if decl.type.CustomType?
            typelist[decl.name] = typelist[decl.type.name]
          end
        end
      end
    end
    typelist
  end

  def self.collect_functions(ast)
    functions = {}
    typelist = collect_types ast
    ast.entities.each do |node|
      node.Declaration? or next
      next if not node.declarators
      node.declarators.each do |decl|
        if decl.type.Function?
          retval = ""
          if node.type.Int?
            retval = "0"
          end
          if node.type.Void?;
            retval = ""
          end
          if node.type.Float?
            retval = "0.0"
          end
          if node.type.CustomType? || node.type.Struct?  || node.type.Enum?
            if typelist[node.type.name]
              retval = typelist[node.type.name][:value]
            else
              puts 'hey!'
              puts node.type.name
            end
          end
          if decl.type.indirect_type.type && decl.type.indirect_type.type.Pointer?
            retval = "NULL"
          end
          sig = "#{node.type.to_s}#{decl.indirect_type.type.to_s} #{decl.name}("
          paramlist = []
          parnum = 0
          if decl.indirect_type.params
            decl.indirect_type.params.each do |param|
              par = "#{param.type.to_s} "
              if param.name
                par << "#{param.name.to_s}"
              else
                par << "par" + parnum.to_s
                parnum = parnum + 1
              end
              paramlist << par
            end
          end
          sig << paramlist.join(", ") << ")\n{\n"
          if retval == ""
            sig << "    return;\n"
          else
            sig << "    return #{retval};\n"
          end
          sig << "}\n"
          functions[decl.name] = {stub:sig, storage:node.storage}
        end
      end
    end
    functions
  end

  def self.make_tree(file, cpp_command="", include_path=[], macros=[])
    code = File.read(file)

    cpp = C::Preprocessor.new
    cpp.include_path.concat include_path
    macros.each do |m|
      s = m.split("=")
      if s.length == 1
        cpp.macros[s[0]] = ''
      else
        cpp.macros[s[0]] = s[1]
      end
    end
    cpp.macros['__attribute__(x)'] = " "
    cpp.macros['__builtin_va_list'] = 'int'
    cpp.macros['__asm(x)'] = " "
    if cpp_command != ""
      C::Preprocessor.command = cpp_command
    end
    source = cpp.preprocess(code)
    source.gsub!(/^#.*/,'')
    C.parse(source)
  end

  def self.make_stubs(files, cpp_command, include_path, macros)
    list = {}
    files.each do |f|
      ast = make_tree(f, cpp_command, include_path, macros)
      list.merge! collect_functions(ast)
    end
    list
  end

  def self.read_filter(file)
    ret = {}
    IO.foreach(file) do |l|
      ret[l.split(' ')[-1]] = true
    end
    ret
  end

  def self.main(argv)
    cpp_command = ''
    include_path = []
    macros = []
    filters = {}
    opt = OptionParser.new
    opt.on('-I/your/include/path') {|v| include_path << v }
    opt.on('-DMACRO') {|v| macros << v }
    opt.on('--cpp Preprocessor') {|v| cpp_command = v }
    opt.on('--filter filter.txt')  {|v| filters.merge! read_filter(v) }
    opt.parse!(argv)

    if argv.length == 0
      puts "error: no input files."
      exit 0
    end
    list = make_stubs(argv, cpp_command, include_path, macros)
    if filters.length == 0
      list.each_pair do |k,v|
        puts v[:stub]
      end
    else
      filters.each_pair do |k,v|
        if list.key? k
          puts list[k][:stub]
        end
      end
    end
  end
end
