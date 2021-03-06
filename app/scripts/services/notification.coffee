angular.module("kvetchApp").service "Notification", ($firebase, $window, $rootScope, Author) ->
  return N =
    init: ({rootId}) ->
      if not $window.Notification?
        return

      $window.Notification.requestPermission()

      messagesRef = new Firebase('https://kvetch.firebaseio.com/messages/')
      messages = $firebase(messagesRef).$asArray()

      messages.$loaded().then ->
        messages.$watch ({event, key}) ->
          $rootScope.$evalAsync ->
            message = messages.$getRecord(key)
            return unless message

            # don't notify if you posted the message yourself
            if message.author && message.author.uid && message.author.uid == Author.get().uid
              return

            if event is 'child_added' and not document.hasFocus()
              parent = message
              found = false
              while true
                break unless parentId = parent?.parents?[0]
                break unless parent = messages.$getRecord(parentId)

                if parent.$id is rootId
                  found = true
                  break

              return unless found

              name = "Oy Vey"
              if message.author && message.author.name
                name = message.author.name

              notice = new $window.Notification name,
                tag: message.$id
                body: message.text
                icon: '/favicon.ico'

              notice.addEventListener 'click', ->
                $window.focus()

                N.lastNotice = {message}

                $rootScope.$broadcast 'notification-click', {message}
