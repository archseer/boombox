class Hash # instead of hash[:key][:key], hash.key.key
  def method_missing(method, *args)
    method_name = method.to_s
    unless respond_to? method_name
      if method_name.ends_with? '?'
        # if it ends with ? it's an existance check
        method_name.slice!(-1)
        key = keys.detect {|k| k.to_s == method_name }
        return !!self[key]
      elsif method_name.ends_with? '='
        # if it ends with = it's a setter, so set the value
        method_name.slice!(-1)
        key = keys.detect {|k| k.to_s == method_name }
        return self[key] = args.first
      end
    end
    # if it contains that key, return the value
    key = keys.detect {|k| k.to_s == method_name }
    return self[key] if key
    super
  end

  # deletes each of the objects without returning the values. should be faster than below.
  def delete_keys *args
    args.each {|arg| self.delete(arg)}
  end

  # deletes each of the objects and returns their values in an array
  def delete_each *args
    args.each_with_object([]) {|arg, obj| obj << self.delete(arg)}
  end
end