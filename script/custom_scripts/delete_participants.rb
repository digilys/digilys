PaperTrail.whodunnit = User.find(4).id # Ev

suite = Suite.find(406)
group = Group.find(363)

suite.participants.each do |pp|

  if pp.group.id != group.id && pp.group.name != 'FA 14/15'
    pp.destroy
  end

end
