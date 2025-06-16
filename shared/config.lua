Config = {}

Config.CommandName = 'detail'
Config.AllowedDurations = {2, 4, 6, 8}
Config.UsageDistance = 4

Config.MarkerType = 28
Config.MarkerScale = vec3(0.4, 0.4, 0.4)
Config.MarkerColor = { r = 255, g = 255, b = 255, a = 200 }
Config.QuestionText = '?'
Config.TextScale = 0.35
Config.TextDuration = 15000 -- milliseconds

Config.CleanupInterval = 300 -- in seconds
Config.EnableRemovalCommand = true
Config.HoldToRemoveKey = 177 -- Backspace
Config.HoldDuration = 5000 -- milliseconds
Config.OwnerOnlyRemove = true -- Only owner can remove, or anyone

Config.HoldToViewKey = 47 -- G
Config.ViewHoldDuration = 5000 -- milliseconds

Config.EnableWebhook = true
Config.Webhook = 'https://discord.com/api/webhooks/your_webhook_url_here'
Config.ShowIdentifiersInWebhook = true
Config.AnonymousMode = false
Config.AdminPermission = "admin"

Config.UseMySQL = true -- true = MySQL / false = JSON fallback
