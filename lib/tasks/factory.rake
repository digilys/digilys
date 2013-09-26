# encoding: UTF-8
# Tasks for generating bulk data
namespace :app do
  namespace :factory do
    FEMALE_FIRST_NAMES = %w(Eva Maria Karin Kristina Lena Kerstin Sara Ingrid Emma Marie Birgitta Malin Jenny Inger Ulla Annika Monica Linda Susanne Elin Hanna Johanna Carina Elisabeth Sofia Katarina Margareta Marianne Anita Helena Emelie Åsa Anette Ida Gunilla Linnéa Camilla Julia Barbro Sandra Siv Ann Anneli Therese Cecilia Josefin Jessica Helen Amanda Gun Lisa Caroline Frida Ulrika Elsa Berit Matilda Maja Madeleine Britt Rebecka Agneta Sofie Pia Rut Yvonne Birgit Ann-Marie Inga Sonja Alice Mona Lina Louise Astrid Ann-Christin Ebba Klara Gunnel Erika Isabelle Britt-Marie Nathalie Moa Alexandra Viktoria Gerd Britta Ellen Irene Lisbeth Pernilla Maj Ella Wilma Felicia Charlotte Ingela Emilia)
    MALE_FIRST_NAMES = %w(Lars Anders Mikael Johan Karl Per Erik Jan Peter Thomas Daniel Fredrik Hans Bengt Mats Andreas Stefan Sven Bo Nils Marcus Magnus Mattias Jonas Niklas Martin Leif Björn Patrik Oskar Ulf Alexander Christer Henrik Joakim Kjell Viktor David Stig Rolf Simon Christoffer Tommy Emil Filip Lennart Robert Gustav Göran Håkan Christian Anton Rickard John Robin Tobias Jonathan Sebastian Kent Jakob William Mohamed Lucas Roger Claes Linus Gunnar Adam Kurt Åke Axel Jesper Jörgen Kenneth Olof Elias Jimmy Arne Rasmus Johnny Isak Albin Dennis Joel Bertil Max Oliver Hugo Pontus Torbjörn Bernt Ludvig Dan Sten Roland Tony Olle Jens Alf Kevin)
    LAST_NAMES = %w(Andersson Johansson Karlsson Nilsson Eriksson Larsson Olsson Persson Svensson Gustafsson Pettersson Jonsson Jansson Hansson Bengtsson Jönsson Lindberg Jakobsson Magnusson Olofsson Lindström Lindqvist Lindgren Axelsson Berg Lundberg Bergström Lundgren Lundqvist Mattsson Lind Berglund Fredriksson Sandberg Henriksson Forsberg Sjöberg Wallin Danielsson Håkansson Engström Eklund Lundin Gunnarsson Holm Fransson Samuelsson Bergman Björk Wikström Isaksson Bergqvist Arvidsson Nyström Holmberg Löfgren Claesson Söderberg Nyberg Blomqvist Mårtensson Nordström Lundström Eliasson Pålsson Björklund Viklund Berggren Sandström Nordin Lund Ström Hermansson Åberg Ekström Holmgren Sundberg Hedlund Dahlberg Hellström Sjögren Abrahamsson Falk Martinsson Andreasson Öberg Blom Månsson Ek Åkesson Strömberg Jonasson Hansen Norberg Sundström Åström Holmqvist Lindholm Sundqvist Ivarsson)

    task students: :environment do
      num = (ENV["num"] || 10).to_i
      1.upto(num) do
        if [0, 1].sample == 1
          first_name = FEMALE_FIRST_NAMES.sample
          gender = :female
        else
          first_name = MALE_FIRST_NAMES.sample
          gender = :male
        end

        instance = Instance.order(:id).first

        student = FactoryGirl.create(
          :student,
          first_name:  first_name,
          last_name:   LAST_NAMES.sample,
          gender:      gender,
          personal_id: "#{(rand(10.years).ago - 6.years).strftime("%Y%m%d")}#{"%04d" % rand(9999)}",
          instance:    instance
        )

        puts "New student: #{student.name}"
      end
    end

    task suite: :environment do
      num = (ENV["evaluations"] || 2).to_i
      results = ENV["results"]

      suite = FactoryGirl.create(:suite, name: "Planering #{DateTime.now.strftime("%Y%m%d%H%M")}")

      puts "New suite: #{suite.name}"

      1.upto(num) do |i|
        evaluation = FactoryGirl.create(:evaluation, name: "Test ##{i}", suite: suite)
        puts "New evaluation: #{evaluation.name}"
      end

      if results
        students = Student.order("random()").limit(10)

        suite.evaluations.each do |evaluation|
          puts "Results for #{evaluation.name}:"


          students.each do |student|
            result = rand(evaluation.max_result + 1)
            FactoryGirl.create(:result, value: result, student: student, evaluation: evaluation)
            puts "\t#{student.name}: #{result}"
          end
        end
      end
    end

    task groups: :environment do
      num_schools = (ENV["schools"] || 2).to_i
      num_classes = (ENV["classes"] || 3).to_i

      1.upto(num_schools) do |i|
        school = FactoryGirl.create(:group, name: "Skola #{i}")
        puts "New school: #{school.name}"

        1.upto(num_classes) do |j|
          cls = FactoryGirl.create(:group, name: "Klass #{j}", parent: school)
          puts "\tNew class: #{cls.name}"
        end
      end
    end
  end
end

