require 'ostruct'

class Counter < Hash
  def initialize
    super { |hash, key| hash[key] = 0 }
  end
end
class Solver
    attr_accessor :raw, :crafts, :craft_seq, :stash

    def initialize(solutions)
        @solutions = solutions
        @crafts = Counter.new
        @craft_seq = Counter.new
        @raw = Counter.new
        @stash = Counter.new
    end

    def process solution, depth, multiplier = 1
        verb, count, tree = solution
        # puts "#{' '*depth}PROCESS: #{verb} * #{count}"
        send verb, depth, multiplier, count, tree
    end

    def get depth, mul, count, item
        puts "#{' '*depth}#{mul} GET #{count} #{item}"
        raw[item] += (mul * count)
    end

    def inspect_stash
      stash.map { |key, value| "#{key.result.name}=#{value}" if value > 0 }.compact.join(',')
    end

    def craft depth, mul, count, tree
        recipe, tail = tree
        puts "#{' '*depth}#{mul} CRAFT #{count} #{recipe.result.name}"
        craft_seq[recipe] = [@craft_seq[recipe] || 0, depth].max
        exact_count = exact_craft(mul * count, recipe.makes)
        new_count = mul * count
        if stash[recipe] >= new_count
          puts "#{' '*depth}HAVE #{new_count}"
          stash[recipe] -= new_count
          puts "#{' '*depth}#{inspect_stash}"
        else
          # puts "#{' '*depth}NUM #{@crafts[recipe]} + #{new_count}"
          stash_count = [exact_count, recipe.makes].max
          # @crafts[recipe] += [count, new_count].max
          crafts[recipe] += exact_count
          puts "#{' '*depth}STASHING #{stash_count} * #{recipe.result.name}"
          stash[recipe] += stash_count
          tail.each do |num, rule|
            process rule, depth+1, new_count
          end
          unstash_count = [new_count, count].max
          puts "#{' '*depth}UNSTASHING #{unstash_count} * #{recipe.result.name}"
          stash[recipe] -= unstash_count
          puts "#{' '*depth}#{inspect_stash}"
        end
    end

    def solve
      @solutions.each do |sol|
        process sol, 0
      end
      self
    end

    def describe
      show_raw
      show_crafts
      show_stash
      nil
    end

    def raw_resources
      raw.sort_by { |item, count| item.name }.map do |item, count|
        stack_info = item.stack_info count.ceil
        [item.name, count.ceil, stack_info]
      end
    end

    def craft_sequence
        ordering = craft_seq.sort_by { |craft, i| i }.reverse
        j, last = 1, ordering.first[1] + 1# max waga
        ordering.map do |craft, order|
          count = crafts[craft]
          row = OpenStruct.new(
            count: (count * craft.makes).round,
            num: (order < last ? j : nil),
            machine: craft.machine,
            result: craft.result,
            ingredients: craft.describe_ingredients(count)
          )
          j += 1 if order < last
          last = order
          row
        end
    end

    def show_raw
        puts "Resources required:"
        raw_resources.each do |name, count, stack_info|
          puts [name, '*', count,
                (" (#{stack_info})" if stack_info)].join ''
        end
    end

    def show_crafts
      last_num = nil
      craft_sequence.each do |row|
        msg = [
          (row.num != nil ? "#{row.num}. " : ' ' * "#{last_num}. ".size),
          ("using #{row.machine} " if row.machine),
          "craft #{row.count} #{row.result} ",
          "from #{row.ingredients}"
        ].join ''
        last_num = row.num
        puts msg
      end
    end

    def show_stash
      puts "Leftovers:"
      stash.each do |recipe, count|
        puts "#{recipe.result.name} * #{count}" if count != 0
      end
    end

end

