String getInitials(String originalString) => originalString.isNotEmpty ? originalString.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase() : 'empty';
