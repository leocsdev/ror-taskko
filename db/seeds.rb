# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed default categories
default_categories = %w[Work Learning Personal Finance Health]

default_categories.each do |category_name|
  Category.find_or_create_by!(name: category_name)
end

# Seed some example tasks
example_tasks = [
  {
    name: "Prepare slide deck for sprint demo",
    description: "Finalize key metrics and architecture diagrams for the presentation.",
    category: "Work",
    priority: "urgent",
    due_at: Time.current.end_of_day
  },
  {
    name: "Review PR for database connection pooling",
    description: "Check migrations, pool size limits, and test coverage before merging.",
    category: "Work",
    priority: "high",
    due_at: 2.days.from_now.change(hour: 17, min: 0)
  },
  {
    name: "Complete Rails 8 Hotwire tutorial",
    description: "Read up on Turbo Frames, Streams, and Stimulus best practices.",
    category: "Learning",
    priority: "medium",
    due_at: 1.week.from_now.change(hour: 20, min: 0)
  },
  {
    name: "Read 'Practical Object-Oriented Design in Ruby'",
    description: "Focus on chapters 3 and 4 about managing dependencies.",
    category: "Learning",
    priority: "low",
    due_at: nil
  },
  {
    name: "Book flight tickets for holiday trip",
    description: "Compare prices and check baggage allowances for the upcoming vacation.",
    category: "Personal",
    priority: "medium",
    due_at: 1.day.from_now.change(hour: 12, min: 0)
  },
  {
    name: "Renew passport appointment",
    description: "Confirmed slot at the consular office and printed out the documents.",
    category: "Personal",
    priority: "low",
    due_at: 1.day.ago.change(hour: 10, min: 0),
    completed_at: 1.day.ago.change(hour: 11, min: 30)
  },
  {
    name: "Pay monthly electricity and internet bills",
    description: "Settle Meralco and Converge accounts before the cutoff date.",
    category: "Finance",
    priority: "high",
    due_at: 1.day.ago.change(hour: 23, min: 59)
  },
  {
    name: "Review monthly budget and credit card statement",
    description: "Audit subscriptions and log discretionary expenses into the tracker.",
    category: "Finance",
    priority: "medium",
    due_at: 4.days.from_now.change(hour: 18, min: 0)
  },
  {
    name: "Schedule annual medical checkup",
    description: "Call the clinic for available weekend morning consultation slots.",
    category: "Health",
    priority: "urgent",
    due_at: Time.current.change(hour: 16, min: 0)
  },
  {
    name: "30-minute afternoon brisk walk",
    description: "Hit the 8,000 steps daily health goal.",
    category: "Health",
    priority: "low",
    due_at: nil
  }
]

example_tasks.each do |task_attrs|
  category = Category.find_by(name: task_attrs[:category])
  Task.find_or_create_by!(name: task_attrs[:name], category: category) do |task|
    task.description = task_attrs[:description]
    task.priority = task_attrs[:priority] || "medium"
    task.due_at = task_attrs[:due_at]
    task.completed_at = task_attrs[:completed_at]
  end
end
