# encoding: UTF-8

Timeliness.add_formats :date, 'd mmmm yy', before: 'm/d/yy'
Timeliness.add_formats :date, 'yy年m月d日'

Timeliness.month_names [
  %w[ ~ Янв Фев Мар Апр Май Июн Июл Авн Сен Окт Ноя Дек ],
  %w[ ~ Января Февраля Марта Апреля Мая Июня Июля Августа Сентября Октября Ноября Декабря ]
]
