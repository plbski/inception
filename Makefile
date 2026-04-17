all:
	docker compose -f srcs/docker-compose.yml up --build -d

down:
	docker compose -f srcs/docker-compose.yml down

re: fclean all

clean:
	docker compose -f srcs/docker-compose.yml down -v

fclean: clean
	docker system prune -af

logs:
	docker compose -f srcs/docker-compose.yml logs -f

.PHONY: all down re clean fclean logs
