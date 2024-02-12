(function() {
    // Функция для отслеживания изменений в полях ввода
    function trackInputChanges() {
        // Получаем все элементы ввода на странице
        var inputFields = document.querySelectorAll('input');

        // Для каждого поля ввода подписываемся на событие изменения
        inputFields.forEach(function(input) {
            input.addEventListener('input', function(event) {
                // Получаем значение поля ввода, которое изменилось
                var value = event.target.value;
                // Действие при изменении значения (можно заменить на другое действие)
                console.log('Изменено значение поля ввода:', value);
            });
        });
    }

    // Вызываем функцию отслеживания изменений при загрузке страницы
    document.addEventListener('DOMContentLoaded', function() {
        trackInputChanges();
    });
})();