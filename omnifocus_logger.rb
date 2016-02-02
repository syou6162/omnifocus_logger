require 'json'
require 'date'

def attach_parent_name!(tree, parent_names = [])
  if tree.has_key?("folders") && (not tree["folders"].empty?)
    tree["folders"].each{|folder|
      names = parent_names.dup.push tree["name"]
      attach_parent_name!(folder, names)
    }
  end
  if tree.has_key?("projects") && (not tree["projects"].empty?)
    tree["projects"].each{|projects|
      names = parent_names.dup.push tree["name"]
      attach_parent_name!(projects, names)
    }
  end
  if tree.has_key?("tasks") && (not tree["tasks"].empty?)
    tree["tasks"].each{|tasks|
      names = parent_names.dup.push tree["name"]
      attach_parent_name!(tasks, names)
    }
  end
  if tree.has_key?("tasks") && tree["tasks"].empty?
    _, *tmp = *parent_names
    tree["parentName"] = tmp.join("/")
  end
  return tree
end

def extract_tasks(tree, result = [])
  if tree.has_key?("folders") && (not tree["folders"].empty?)
    tree["folders"].each{|folder|
      extract_tasks(folder, result)
    }
  end
  if tree.has_key?("projects") && (not tree["projects"].empty?)
    tree["projects"].each{|projects|
      extract_tasks(projects, result)
    }
  end
  if tree.has_key?("tasks") && (not tree["tasks"].empty?)
    tree["tasks"].each{|tasks|
      extract_tasks(tasks, result)
    }
  end
  if tree.has_key?("tasks") && tree["tasks"].empty?
    result.push tree
  end
  return result
end

def attach_readable_time!(task, field)
  if not task[field].nil?
    timezone = 64800 # 18 * 60 * 60
    date = DateTime.strptime(((task[field] / 1000) + timezone).to_s, '%s')
    task[field] = date.strftime("%Y-%m-%d %H:%M:%S +0900")
  end
  task
end

index = "omnifocus"
type = "task"
`curl -XDELETE http://localhost:9200/#{index}`

`curl -XPUT localhost:9200/#{index} -d '{
  "mappings": {
    "#{type}": {
      "properties": {
        "dateAdded": { "type": "date", "format": "yyyy-MM-dd HH:mm:ss Z" },
        "dateModified": { "type": "date", "format": "yyyy-MM-dd HH:mm:ss Z" },
        "deferDate": { "type": "date", "format": "yyyy-MM-dd HH:mm:ss Z" },
        "dueDate": { "type": "date", "format": "yyyy-MM-dd HH:mm:ss Z" },
        "completionDate": { "type": "date", "format": "yyyy-MM-dd HH:mm:ss Z" }
      }
    }
  }
}'`

json_str = ""
STDIN.each{|line|
  json_str += line
}

tree = attach_parent_name! JSON.parse(json_str)

extract_tasks(tree).each{|task|
  attach_readable_time!(task, "dateAdded")
  attach_readable_time!(task, "dateModified")
  attach_readable_time!(task, "deferDate")
  attach_readable_time!(task, "dueDate")
  attach_readable_time!(task, "completionDate")
  id = task["id"]
  puts "{ \"index\" : { \"_index\" : \"#{index}\", \"_type\" : \"#{type}\", \"_id\" : \"#{id}\" } }"
  puts task.to_json
}
